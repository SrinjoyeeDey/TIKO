import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('eval')
external JSAny? _jsEval(JSString code);

void _ensureRecorderInjected() {
  const jsCode = r''';
  if (!window.nimoAudioRecorder) {
    window.nimoAudioRecorder = {
      mediaRecorder: null,
      audioChunks: [],
      stream: null,
      speechRecognition: null,
      liveTranscript: '',
      
      start: async function() {
        try {
          this.audioChunks = [];
          this.liveTranscript = '';
          this.stream = await navigator.mediaDevices.getUserMedia({ 
            audio: {
              echoCancellation: true,
              noiseSuppression: true,
              autoGainControl: true
            } 
          });
          
          let mimeType = 'audio/webm';
          if (typeof MediaRecorder !== 'undefined') {
            if (MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
              mimeType = 'audio/webm;codecs=opus';
            } else if (MediaRecorder.isTypeSupported('audio/ogg;codecs=opus')) {
              mimeType = 'audio/ogg;codecs=opus';
            }
          }
          
          this.mediaRecorder = new MediaRecorder(this.stream, { mimeType: mimeType });
          this.mediaRecorder.ondataavailable = (e) => {
            if (e.data && e.data.size > 0) {
              this.audioChunks.push(e.data);
            }
          };
          this.mediaRecorder.start(100);

          const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
          if (SpeechRec) {
            try {
              this.speechRecognition = new SpeechRec();
              this.speechRecognition.continuous = true;
              this.speechRecognition.interimResults = true;
              this.speechRecognition.lang = 'en-IN';
              this.speechRecognition.onresult = (event) => {
                let text = '';
                for (let i = 0; i < event.results.length; i++) {
                  text += event.results[i][0].transcript + ' ';
                }
                window.nimoAudioRecorder.liveTranscript = text.trim();
              };
              this.speechRecognition.start();
            } catch (e) {
              console.warn('SpeechRecognition init:', e);
            }
          }
          return true;
        } catch (err) {
          console.error('Audio recorder start error:', err);
          return false;
        }
      },

      stop: function() {
        return new Promise((resolve) => {
          try {
            if (this.speechRecognition) {
              try { this.speechRecognition.stop(); } catch(_) {}
            }
            if (!this.mediaRecorder || this.mediaRecorder.state === 'inactive') {
              resolve(JSON.stringify({ base64Audio: '', transcript: this.liveTranscript || '' }));
              return;
            }
            this.mediaRecorder.onstop = () => {
              const blob = new Blob(this.audioChunks, { type: this.mediaRecorder.mimeType || 'audio/webm' });
              if (this.stream) {
                this.stream.getTracks().forEach(track => track.stop());
              }
              const reader = new FileReader();
              reader.onloadend = () => {
                const res = reader.result || '';
                const base64Audio = res.includes(',') ? res.split(',')[1] : '';
                resolve(JSON.stringify({ 
                  base64Audio: base64Audio, 
                  transcript: window.nimoAudioRecorder.liveTranscript || '',
                  mimeType: blob.type
                }));
              };
              reader.readAsDataURL(blob);
            };
            this.mediaRecorder.stop();
          } catch (err) {
            console.error('Audio recorder stop error:', err);
            resolve(JSON.stringify({ base64Audio: '', transcript: this.liveTranscript || '' }));
          }
        });
      }
    };
  }

  if (!window.nimoAudioRecorderStart) {
    window.nimoAudioRecorderStart = function() {
      return window.nimoAudioRecorder ? window.nimoAudioRecorder.start() : Promise.resolve(false);
    };
  }

  if (!window.nimoAudioRecorderStop) {
    window.nimoAudioRecorderStop = function() {
      return window.nimoAudioRecorder ? window.nimoAudioRecorder.stop() : Promise.resolve('{}');
    };
  }

  if (!window.nimoEnsureWebcam) {
    window.nimoEnsureWebcam = async function() {
      try {
        if (window._nimoWebcamStream && window._nimoWebcamStream.active) {
          const tracks = window._nimoWebcamStream.getVideoTracks();
          if (tracks.some(t => t.readyState === 'live' && t.enabled)) {
            return true;
          }
        }
        const stream = await navigator.mediaDevices.getUserMedia({
          video: {
            facingMode: 'user',
            width: { ideal: 640 },
            height: { ideal: 480 }
          },
          audio: false
        });
        window._nimoWebcamStream = stream;
        if (!window._nimoWebcamVideo) {
          window._nimoWebcamVideo = document.createElement('video');
          window._nimoWebcamVideo.setAttribute('playsinline', '');
          window._nimoWebcamVideo.setAttribute('muted', '');
          window._nimoWebcamVideo.muted = true;
          window._nimoWebcamVideo.autoplay = true;
          window._nimoWebcamVideo.style.position = 'fixed';
          window._nimoWebcamVideo.style.top = '-9999px';
          window._nimoWebcamVideo.style.left = '-9999px';
          window._nimoWebcamVideo.style.width = '320px';
          window._nimoWebcamVideo.style.height = '240px';
          window._nimoWebcamVideo.style.opacity = '0.01';
          window._nimoWebcamVideo.style.pointerEvents = 'none';
          window._nimoWebcamVideo.style.zIndex = '-9999';
          document.body.appendChild(window._nimoWebcamVideo);
        }
        window._nimoWebcamVideo.srcObject = stream;
        await window._nimoWebcamVideo.play();
        return true;
      } catch (err) {
        console.warn('nimoEnsureWebcam error:', err);
        return false;
      }
    };
  }

  if (!window.nimoCaptureVideoFrame) {
    window.nimoCaptureVideoFrame = function() {
      try {
        let videos = Array.from(document.querySelectorAll('video'));
        document.querySelectorAll('flt-platform-view, flt-scene-host').forEach(host => {
          if (host.shadowRoot) {
            videos.push(...Array.from(host.shadowRoot.querySelectorAll('video')));
          }
        });

        let video = null;

        // 1. Prioritize any video element with active video dimensions
        for (let v of videos) {
          if (v.videoWidth > 0 && v.videoHeight > 0) {
            video = v;
            break;
          }
        }

        // 2. Check dedicated background webcam video element
        if (!video && window._nimoWebcamVideo && window._nimoWebcamVideo.videoWidth > 0) {
          video = window._nimoWebcamVideo;
        }

        if (!video) {
          if (typeof window.nimoEnsureWebcam === 'function') {
            window.nimoEnsureWebcam();
          }
          return '';
        }

        const canvas = document.createElement('canvas');
        const scale = Math.min(1.0, 640 / Math.max(1, video.videoWidth));
        canvas.width = Math.round(video.videoWidth * scale);
        canvas.height = Math.round(video.videoHeight * scale);
        const ctx = canvas.getContext('2d');
        if (!ctx) return '';
        ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
        const dataUrl = canvas.toDataURL('image/jpeg', 0.80);
        return dataUrl.includes(',') ? dataUrl.split(',')[1] : '';
      } catch(e) {
        console.warn('Video frame capture error:', e);
        return '';
      }
    };
  }


  if (!window.nimoDetectFaceLocal) {
    window.nimoDetectFaceLocal = function() {
      try {
        let videos = Array.from(document.querySelectorAll('video'));
        document.querySelectorAll('flt-platform-view, flt-scene-host').forEach(host => {
          if (host.shadowRoot) {
            videos.push(...Array.from(host.shadowRoot.querySelectorAll('video')));
          }
        });

        let video = null;
        for (let v of videos) {
          if (v.videoWidth > 0 && v.videoHeight > 0) {
            video = v;
            break;
          }
        }
        if (!video && window._nimoWebcamVideo && window._nimoWebcamVideo.videoWidth > 0) {
          video = window._nimoWebcamVideo;
        }
        if (!video) return JSON.stringify({ faceDetected: false });

        const canvas = document.createElement('canvas');
        canvas.width = 160;
        canvas.height = 120;
        const ctx = canvas.getContext('2d');
        if (!ctx) return JSON.stringify({ faceDetected: false });
        ctx.drawImage(video, 0, 0, 160, 120);

        const imgData = ctx.getImageData(0, 0, 160, 120);
        const data = imgData.data;

        let skinPixels = 0;
        let totalCenterPixels = 0;

        for (let y = 20; y < 100; y += 2) {
          for (let x = 30; x < 130; x += 2) {
            const idx = (y * 160 + x) * 4;
            const r = data[idx];
            const g = data[idx + 1];
            const b = data[idx + 2];
            totalCenterPixels++;

            if (r > 45 && g > 30 && b > 20 && r > g && r > b && (Math.max(r,g,b) - Math.min(r,g,b)) > 12) {
              skinPixels++;
            }
          }
        }

        const skinRatio = skinPixels / Math.max(1, totalCenterPixels);
        const faceDetected = skinRatio > 0.18;

        return JSON.stringify({
          faceDetected: faceDetected,
          personDetected: faceDetected,
          lookingAtScreen: faceDetected,
          mouthMovement: false,
          mouthOpen: false,
          engagementScore: faceDetected ? 85 : 0,
          facialExpression: faceDetected ? "ATTENTIVE" : "NO_FACE",
          headOrientation: faceDetected ? "FRONTAL" : "UNKNOWN"
        });
      } catch(e) {
        return JSON.stringify({ faceDetected: false });
      }
    };
  }

  if (!window.nimoSpeakText) {
    window.nimoSpeakText = function(text) {
      if (window.speechSynthesis) {
        window.speechSynthesis.cancel();
        const u = new SpeechSynthesisUtterance(text);
        u.lang = 'en-US';
        u.rate = 0.95;
        window.speechSynthesis.speak(u);
      }
    };
  }

  if (!window.nimoCancelSpeech) {
    window.nimoCancelSpeech = function() {
      if (window.speechSynthesis) window.speechSynthesis.cancel();
      if (window.nimoCurrentAudio) {
        try { window.nimoCurrentAudio.pause(); } catch(_) {}
        window.nimoCurrentAudio = null;
      }
    };
  }

  if (!window.nimoPlayAudioSrc) {
    window.nimoPlayAudioSrc = function(src) {
      if (window.nimoCancelSpeech) window.nimoCancelSpeech();
      const audio = new Audio(src);
      window.nimoCurrentAudio = audio;
      audio.play().catch(e => console.warn('Audio play error:', e));
    };
  }
  ''';
  try {
    _jsEval(jsCode.toJS);
  } catch (e) {
    debugPrint('WebAudioHelper injection note: $e');
  }
}

@JS('nimoAudioRecorderStart')
external JSPromise<JSBoolean> _jsStart();

@JS('nimoAudioRecorderStop')
external JSPromise<JSString> _jsStop();

@JS('nimoCaptureVideoFrame')
external JSString _jsCaptureFrame();

@JS('nimoEnsureWebcam')
external JSPromise<JSBoolean> _jsEnsureWebcam();

@JS('nimoSpeakText')
external void _jsSpeakText(JSString text);

@JS('nimoCancelSpeech')
external void _jsCancelSpeech();

@JS('nimoPlayAudioSrc')
external void _jsPlayAudioSrc(JSString src);

Future<bool> ensureWebCameraReadyImpl() async {
  try {
    _ensureRecorderInjected();
    final promise = _jsEnsureWebcam();
    final jsBool = await promise.toDart;
    return jsBool.toDart;
  } catch (e) {
    debugPrint('WebAudioHelper ensureWebcam error: $e');
    return false;
  }
}

String? captureWebFrameImpl() {
  try {
    _ensureRecorderInjected();
    final jsStr = _jsCaptureFrame();
    final base64Str = jsStr.toDart;
    if (base64Str.isNotEmpty) {
      return base64Str;
    }
  } catch (e) {
    debugPrint('WebAudioHelper captureWebFrame error: $e');
  }
  return null;
}

Future<bool> startWebRecordingImpl() async {
  try {
    _ensureRecorderInjected();
    final promise = _jsStart();
    final jsBool = await promise.toDart;
    final success = jsBool.toDart;
    debugPrint('WebAudioHelper: nimoAudioRecorderStart() returned $success');
    return success;
  } catch (e) {
    debugPrint('WebAudioHelper start error: $e');
  }
  return false;
}

Future<Map<String, dynamic>?> stopWebRecordingImpl() async {
  try {
    _ensureRecorderInjected();
    final promise = _jsStop();
    final jsStr = await promise.toDart;
    final jsonString = jsStr.toDart;
    if (jsonString.isNotEmpty) {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final base64Str = map['base64Audio'] as String? ?? '';
      final transcript = map['transcript'] as String? ?? '';
      List<int> bytes = [];
      if (base64Str.isNotEmpty) {
        bytes = base64.decode(base64Str);
      }
      debugPrint(
        'WebAudioHelper: Received ${bytes.length} bytes from browser. Web transcript: "$transcript"',
      );
      return {'bytes': bytes, 'transcript': transcript};
    }
  } catch (e) {
    debugPrint('WebAudioHelper stop error: $e');
  }
  return null;
}

void speakWebTextImpl(String text, VoidCallback onEnded) {
  try {
    _ensureRecorderInjected();
    _jsSpeakText(text.toJS);
  } catch (e) {
    debugPrint('speakWebTextImpl error: $e');
  }
}

void cancelWebSpeechImpl() {
  try {
    _ensureRecorderInjected();
    _jsCancelSpeech();
  } catch (e) {
    debugPrint('cancelWebSpeechImpl error: $e');
  }
}

void playWebAudioSourceImpl(String src, VoidCallback onEnded) {
  try {
    _ensureRecorderInjected();
    _jsPlayAudioSrc(src.toJS);
  } catch (e) {
    debugPrint('playWebAudioSourceImpl error: $e');
  }
}

@JS('nimoDetectFaceLocal')
external JSString _jsDetectFaceLocal();

String? detectFaceLocalImpl() {
  try {
    _ensureRecorderInjected();
    final jsStr = _jsDetectFaceLocal();
    final str = jsStr.toDart;
    if (str.isNotEmpty) return str;
  } catch (e) {
    debugPrint('detectFaceLocalImpl error: $e');
  }
  return null;
}
