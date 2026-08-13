document.addEventListener('DOMContentLoaded', () => {
  // ===================================================
  // SCREEN NAVIGATION — Age → Takeover Animation → Role Selection
  // ===================================================
  const ageScreen      = document.getElementById('sego-screen');
  const takeoverScreen = document.getElementById('takeover-screen');
  const roleScreen     = document.getElementById('role-screen');
  const continueBtn    = document.getElementById('age-continue-btn');
  const roleBackBtn    = document.getElementById('role-back-btn');
  const roleAgeBadge   = document.getElementById('role-age-badge');
  const roleChildBtn   = document.getElementById('role-child-btn');
  const roleParentBtn  = document.getElementById('role-parent-btn');

  let currentSelectedAge = 7;
  let isTakeoverAnimPlaying = false;

  function showRoleScreen() {
    if (roleAgeBadge) roleAgeBadge.textContent = `Age: ${currentSelectedAge}`;
    if (takeoverScreen) takeoverScreen.classList.remove('active');
    if (ageScreen) ageScreen.classList.remove('active');
    setTimeout(() => {
      if (roleScreen) roleScreen.classList.add('active');
    }, 120);
  }

  function showAgeScreen() {
    if (roleScreen) roleScreen.classList.remove('active');
    if (takeoverScreen) takeoverScreen.classList.remove('active');
    setTimeout(() => {
      if (ageScreen) ageScreen.classList.add('active');
    }, 120);
  }

  function startTakeoverSequence(age) {
    currentSelectedAge = age;
    if (ageScreen) ageScreen.classList.remove('active');
    setTimeout(() => {
      if (takeoverScreen) {
        takeoverScreen.classList.add('active');
        playTakeoverAnimation();
      }
    }, 120);
  }

  const scrollUpBtn    = document.getElementById('scroll-up-btn');
  const scrollUpPrompt = document.getElementById('scroll-up-prompt');

  let isTakeoverTriggered = false;

  function triggerTakeoverFromAge() {
    if (isTakeoverTriggered) return;
    if (!ageScreen || !ageScreen.classList.contains('active')) return;
    isTakeoverTriggered = true;

    const age = parseInt(document.getElementById('selected-age-display')?.textContent) || 7;
    startTakeoverSequence(age);
  }

  // Reset trigger flag if returning to age screen
  const originalShowAgeScreen = showAgeScreen;
  showAgeScreen = function() {
    isTakeoverTriggered = false;
    originalShowAgeScreen();
  };

  // 1. Click on scroll button with ^ arrow
  if (scrollUpBtn) {
    scrollUpBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      triggerTakeoverFromAge();
    });
  }
  if (scrollUpPrompt) {
    scrollUpPrompt.addEventListener('click', (e) => {
      e.stopPropagation();
      triggerTakeoverFromAge();
    });
  }

  // 2. Mouse Wheel Scroll (Triggers on ANY wheel scroll up/down movement!)
  let wheelThrottle = 0;
  window.addEventListener('wheel', (e) => {
    if (!ageScreen || !ageScreen.classList.contains('active')) return;
    const now = Date.now();
    if (Math.abs(e.deltaY) > 5 && (now - wheelThrottle > 600)) {
      wheelThrottle = now;
      triggerTakeoverFromAge();
    }
  }, { passive: true });

  // 3. Window Scroll Event (in case browser performs actual page scroll)
  window.addEventListener('scroll', () => {
    if (!ageScreen || !ageScreen.classList.contains('active')) return;
    if (window.scrollY > 10) {
      triggerTakeoverFromAge();
    }
  }, { passive: true });

  // 4. Keyboard Navigation (ArrowUp, ArrowDown, PageDown, Space)
  window.addEventListener('keydown', (e) => {
    if (!ageScreen || !ageScreen.classList.contains('active')) return;
    if (['ArrowDown', 'ArrowUp', 'PageDown', 'PageUp', ' '].includes(e.key)) {
      triggerTakeoverFromAge();
    }
  });

  // 5. Touch Swipe Up/Down Gesture for Mobile & Touchpads
  let touchStartY = 0;
  window.addEventListener('touchstart', (e) => {
    if (e.touches && e.touches.length > 0) {
      touchStartY = e.touches[0].clientY;
    }
  }, { passive: true });

  window.addEventListener('touchend', (e) => {
    if (!ageScreen || !ageScreen.classList.contains('active')) return;
    if (e.changedTouches && e.changedTouches.length > 0) {
      const touchEndY = e.changedTouches[0].clientY;
      const deltaY = touchEndY - touchStartY;
      if (Math.abs(deltaY) > 25) { // Swiped up or down
        triggerTakeoverFromAge();
      }
    }
  }, { passive: true });

  if (takeoverScreen) {
    takeoverScreen.addEventListener('click', () => {
      showRoleScreen();
    });
  }

  if (roleBackBtn) {
    roleBackBtn.addEventListener('click', showAgeScreen);
  }

  // ── HOPPING BALL & TYPEWRITER ANIMATION ────────────────────────────
  function playTakeoverAnimation() {
    const ball = document.getElementById('hopping-ball');
    const line1 = document.getElementById('takeover-line-1');
    const line2 = document.getElementById('takeover-line-2');
    const prompt = document.getElementById('takeover-tap-prompt');
    if (!ball || !line1 || !line2) return;

    const fullText1 = "EVERYONE'S JOURNEY IS DIFFERENT";
    const fullText2 = "BUT YOURS IS SPECIAL";

    line1.textContent = "";
    line2.textContent = "";
    if (prompt) prompt.classList.remove('visible');

    ball.style.opacity = '1';
    ball.style.transition = 'none';

    const rect1 = line1.getBoundingClientRect();
    const rect2 = line2.getBoundingClientRect();

    let index1 = 0;
    let index2 = 0;

    // Start ball at top center
    const startX = window.innerWidth / 2;
    const startY = -40;
    ball.style.left = `${startX}px`;
    ball.style.top = `${startY}px`;

    // Step 1: Drop ball down to line 1
    setTimeout(() => {
      ball.style.transition = 'top 0.4s cubic-bezier(0.5, 0, 0.75, 0), left 0.4s ease-out';
      const targetY1 = rect1.top + rect1.height / 2;
      const targetX1 = Math.max(40, rect1.left + 20);
      ball.style.left = `${targetX1}px`;
      ball.style.top = `${targetY1 - 25}px`;

      // Step 2: Write Line 1 character by character as ball hops
      setTimeout(() => {
        const interval1 = setInterval(() => {
          if (index1 < fullText1.length) {
            index1++;
            line1.textContent = fullText1.substring(0, index1);
            
            // Move ball horizontally across line 1 with a small hop
            const curRect = line1.getBoundingClientRect();
            const progress = index1 / fullText1.length;
            const curX = curRect.left + curRect.width * progress;
            const hopY = (index1 % 2 === 0) ? -16 : 0;

            ball.style.transition = 'left 0.08s linear, top 0.08s ease-out';
            ball.style.left = `${curX}px`;
            ball.style.top = `${curRect.top + curRect.height / 2 + hopY}px`;
          } else {
            clearInterval(interval1);
            // Move to Line 2
            startLine2();
          }
        }, 65);
      }, 420);
    }, 100);

    function startLine2() {
      const curRect2 = line2.getBoundingClientRect();
      ball.style.transition = 'top 0.35s cubic-bezier(0.5, 0, 0.75, 0), left 0.35s ease';
      ball.style.left = `${Math.max(40, curRect2.left + 20)}px`;
      ball.style.top = `${curRect2.top + curRect2.height / 2 - 20}px`;

      setTimeout(() => {
        const interval2 = setInterval(() => {
          if (index2 < fullText2.length) {
            index2++;
            line2.textContent = fullText2.substring(0, index2);

            const curRect = line2.getBoundingClientRect();
            const progress = index2 / fullText2.length;
            const curX = curRect.left + curRect.width * progress;
            const hopY = (index2 % 2 === 0) ? -18 : 0;

            ball.style.transition = 'left 0.08s linear, top 0.08s ease-out';
            ball.style.left = `${curX}px`;
            ball.style.top = `${curRect.top + curRect.height / 2 + hopY}px`;
          } else {
            clearInterval(interval2);
            // Ball rolls away off to the right side!
            finishBallAnimation();
          }
        }, 75);
      }, 380);
    }

    function finishBallAnimation() {
      // Ball rolls right off screen
      ball.style.transition = 'left 0.8s cubic-bezier(0.25, 1, 0.5, 1), top 0.8s ease-in, opacity 0.6s ease-in';
      ball.style.left = `${window.innerWidth + 80}px`;
      ball.style.top = `${window.innerHeight / 2 + 100}px`;
      ball.style.opacity = '0';

      // Show tap prompt
      setTimeout(() => {
        if (prompt) prompt.classList.add('visible');
      }, 600);
    }
  }


  // Role card selection — animate chosen card, mark as selected
  function handleRoleSelect(btn, role) {
    document.querySelectorAll('.role-card').forEach(c => c.classList.remove('chosen'));
    btn.classList.add('chosen');
    btn.querySelector('.role-card-label').textContent =
      role === 'child' ? '✓ I\'m a Child' : '✓ I\'m a Parent';

    // Could navigate further here — for now shows a chosen state
    setTimeout(() => {
      console.log(`Role selected: ${role}, age: ${roleAgeBadge?.textContent}`);
    }, 400);
  }

  if (roleChildBtn) roleChildBtn.addEventListener('click', () => handleRoleSelect(roleChildBtn, 'child'));
  if (roleParentBtn) roleParentBtn.addEventListener('click', () => handleRoleSelect(roleParentBtn, 'parent'));

  // Parallax Mouse Movement effect for Topo Lines & Kanji Watermark
  const kanjiWatermark = document.querySelector('.kanji-watermark');
  const topoBgSvg = document.querySelector('.topo-bg-svg');

  document.addEventListener('mousemove', (e) => {
    const mouseX = e.clientX / window.innerWidth - 0.5;
    const mouseY = e.clientY / window.innerHeight - 0.5;

    if (kanjiWatermark) {
      kanjiWatermark.style.transform = `translate(${mouseX * 20}px, ${mouseY * 20}px)`;
    }

    if (topoBgSvg) {
      topoBgSvg.style.transform = `scale(1.05) translate(${mouseX * -15}px, ${mouseY * -15}px)`;
    }
  });

  // ===================================================
  // INTERACTIVE MONSTER TEETH AGE SELECTOR DRAG LOGIC
  // ===================================================
  const teethTrack = document.getElementById('teeth-track');
  const teethContainer = document.getElementById('monster-teeth-container');
  const ageDisplay = document.getElementById('selected-age-display');
  const btnPrev = document.getElementById('age-prev-btn');
  const btnNext = document.getElementById('age-next-btn');

  // ── Age Range Colour Themes ──────────────────────────────────────────
  // Each theme: cardTop, cardBottom, bgEnd, bgBlend, mouthTop, mouthBottom,
  //             accentDark, toothGlow, toothText, shadowColor
  const THEMES = {
    green: {
      cardTop:     '#94D561', cardBottom:  '#6AAE38',
      bgEnd:       '#82C54F', bgBlend:     '#D3F1BA',
      mouthTop:    '#1C4108', mouthBottom: '#0E2203',
      accentDark:  '#1C4108',
      toothGlow:   'rgba(148,213,97,0.65)',
      toothText:   '#6DA838',
      shadow:      'rgba(14,34,3,0.28)',
    },
    yellow: {
      cardTop:     '#FFBF27', cardBottom:  '#E89B00',
      bgEnd:       '#F5A800', bgBlend:     '#FFF0B0',
      mouthTop:    '#5C3A00', mouthBottom: '#3A2200',
      accentDark:  '#5C3A00',
      toothGlow:   'rgba(255,191,39,0.65)',
      toothText:   '#B87800',
      shadow:      'rgba(58,34,0,0.28)',
    },
    pink: {
      cardTop:     '#FF3B63', cardBottom:  '#CC1A40',
      bgEnd:       '#E8274F', bgBlend:     '#FFBECB',
      mouthTop:    '#5C001A', mouthBottom: '#3A0010',
      accentDark:  '#5C001A',
      toothGlow:   'rgba(255,59,99,0.65)',
      toothText:   '#CC3355',
      shadow:      'rgba(58,0,16,0.28)',
    },
    purple: {
      cardTop:     '#A855F7', cardBottom:  '#7C23D4',
      bgEnd:       '#9333EA', bgBlend:     '#E8C8FF',
      mouthTop:    '#2D0A4E', mouthBottom: '#1A0030',
      accentDark:  '#2D0A4E',
      toothGlow:   'rgba(168,85,247,0.65)',
      toothText:   '#9B4DCC',
      shadow:      'rgba(26,0,48,0.28)',
    },
  };

  function getThemeForAge(age) {
    if (age <= 5)  return THEMES.green;
    if (age <= 8)  return THEMES.yellow;
    if (age <= 11) return THEMES.pink;
    return THEMES.purple;
  }

  // Lerp two hex/rgb colors (as css strings) — done via CSS vars + transition
  function applyTheme(theme) {
    const root = document.documentElement;
    root.style.setProperty('--theme-card-top',      theme.cardTop);
    root.style.setProperty('--theme-card-bottom',   theme.cardBottom);
    root.style.setProperty('--theme-bg-end',        theme.bgEnd);
    root.style.setProperty('--theme-bg-blend',      theme.bgBlend);
    root.style.setProperty('--theme-mouth-top',     theme.mouthTop);
    root.style.setProperty('--theme-mouth-bottom',  theme.mouthBottom);
    root.style.setProperty('--theme-accent-dark',   theme.accentDark);
    root.style.setProperty('--theme-tooth-glow',    theme.toothGlow);
    root.style.setProperty('--theme-tooth-text',    theme.toothText);
    root.style.setProperty('--theme-shadow',        theme.shadow);

    // Also update eyebrow / nostril colors directly
    document.querySelectorAll('.monster-eyebrow').forEach(el => {
      el.style.borderTopColor = theme.accentDark;
    });
    document.querySelectorAll('.nostril-hole').forEach(el => {
      el.style.background = theme.accentDark + 'A6'; // ~65% opacity
    });
    document.querySelectorAll('.monster-eye').forEach(el => {
      el.style.borderColor = theme.accentDark;
    });
  }

  if (teethTrack && teethContainer) {
    const minAge = 3;
    const maxAge = 15;
    let currentAge = 7;
    const itemWidth = 44;
    let lastThemeKey = 'yellow';

    // Populate teeth (ages 3 to 15)
    for (let age = minAge; age <= maxAge; age++) {
      const tooth = document.createElement('div');
      tooth.className = `tooth-item ${age === currentAge ? 'active' : ''}`;
      tooth.dataset.age = age;
      tooth.innerText = age;
      tooth.addEventListener('click', () => selectAge(age));
      teethTrack.appendChild(tooth);
    }

    function selectAge(age) {
      currentAge = Math.max(minAge, Math.min(maxAge, age));
      updateTeethPosition();
    }

    function getThemeKey(age) {
      if (age <= 5)  return 'green';
      if (age <= 8)  return 'yellow';
      if (age <= 11) return 'pink';
      return 'purple';
    }

    function updateTeethPosition() {
      const activeIndex = currentAge - minAge;
      const offset = -activeIndex * itemWidth;
      teethTrack.style.transform = `translateX(${offset}px)`;

      const theme = getThemeForAge(currentAge);
      const themeKey = getThemeKey(currentAge);

      // Only animate theme change on range boundary crossing
      if (themeKey !== lastThemeKey) {
        lastThemeKey = themeKey;
        applyTheme(theme);
      }

      // Update 3D Perspective Transformation for each tooth
      const toothItems = teethTrack.querySelectorAll('.tooth-item');
      toothItems.forEach((item) => {
        const itemAge = parseInt(item.dataset.age);
        const signedOffset = itemAge - currentAge;
        const dist = Math.abs(signedOffset);

        const width = Math.max(34, 58 - dist * 5.0);
        const height = Math.max(38, 105 - dist * 15.0);
        const fontSize = Math.max(0.95, 1.9 - dist * 0.15);

        if (itemAge === currentAge) {
          item.classList.add('active');
          item.style.transform = `translateY(0px) translateZ(25px) rotateY(0deg)`;
          item.style.width = `${width}px`;
          item.style.height = `${height}px`;
          item.style.fontSize = `${fontSize}rem`;
          item.style.borderRadius = `0 0 ${width * 0.45}px ${width * 0.45}px`;
          item.style.opacity = '1.0';
          item.style.zIndex = '10';
          item.style.boxShadow = `0 8px 18px rgba(0,0,0,0.45), 0 0 22px 2px ${theme.toothGlow}`;
          item.style.color = theme.accentDark;
        } else {
          item.classList.remove('active');
          const rotateY = -signedOffset * 8;
          const translateZ = 25 - dist * dist * 15;
          const opacity = Math.max(0.60, 1.0 - dist * 0.08);

          item.style.transform = `translateY(0px) translateZ(${translateZ}px) rotateY(${rotateY}deg)`;
          item.style.width = `${width}px`;
          item.style.height = `${height}px`;
          item.style.fontSize = `${fontSize}rem`;
          item.style.borderRadius = `0 0 ${width * 0.45}px ${width * 0.45}px`;
          item.style.opacity = opacity;
          item.style.zIndex = Math.max(1, 10 - dist);
          item.style.boxShadow = `0 2px 4px rgba(0,0,0,0.20)`;
          item.style.color = theme.toothText;
        }
      });

      if (ageDisplay) {
        ageDisplay.innerText = `${currentAge} Years`;
      }
    }

    // Prev / Next button clicks
    if (btnPrev) btnPrev.addEventListener('click', () => selectAge(currentAge - 1));
    if (btnNext) btnNext.addEventListener('click', () => selectAge(currentAge + 1));

    // Mouse & Touch Dragging physics
    let isDragging = false;
    let startX = 0;
    let startAge = currentAge;

    teethContainer.addEventListener('mousedown', (e) => {
      isDragging = true;
      startX = e.clientX;
      startAge = currentAge;
      teethTrack.style.transition = 'none';
    });

    window.addEventListener('mousemove', (e) => {
      if (!isDragging) return;
      const deltaX = e.clientX - startX;
      const ageDelta = Math.round(-deltaX / itemWidth);
      const newAge = startAge + ageDelta;
      if (newAge >= minAge && newAge <= maxAge && newAge !== currentAge) {
        currentAge = newAge;
        updateTeethPosition();
      }
    });

    window.addEventListener('mouseup', () => {
      if (isDragging) {
        isDragging = false;
        teethTrack.style.transition = 'transform 0.3s cubic-bezier(0.25, 1, 0.5, 1)';
        updateTeethPosition();
      }
    });

    // Touch events for tablets/mobiles
    teethContainer.addEventListener('touchstart', (e) => {
      isDragging = true;
      startX = e.touches[0].clientX;
      startAge = currentAge;
      teethTrack.style.transition = 'none';
    });

    teethContainer.addEventListener('touchmove', (e) => {
      if (!isDragging) return;
      const deltaX = e.touches[0].clientX - startX;
      const ageDelta = Math.round(-deltaX / itemWidth);
      const newAge = startAge + ageDelta;
      if (newAge >= minAge && newAge <= maxAge && newAge !== currentAge) {
        currentAge = newAge;
        updateTeethPosition();
      }
    });

    teethContainer.addEventListener('touchend', () => {
      if (isDragging) {
        isDragging = false;
        teethTrack.style.transition = 'transform 0.3s cubic-bezier(0.25, 1, 0.5, 1)';
        updateTeethPosition();
      }
    });

    // Initial positioning + theme
    applyTheme(getThemeForAge(currentAge));
    updateTeethPosition();
  }
});

