import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('eval')
external JSAny? _jsEval(JSString code);

void _ensureRecorderInjected() {
  const jsCode = r'''
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
      debugPrint('WebAudioHelper: Received ${bytes.length} bytes from browser. Web transcript: "$transcript"');
      return {
        'bytes': bytes,
        'transcript': transcript,
      };
    }
  } catch (e) {
    debugPrint('WebAudioHelper stop error: $e');
  }
  return null;
}
