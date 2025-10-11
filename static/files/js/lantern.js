(function(){
    const container = document.querySelector('.lantern-container');
    if(!container) return;
    const lantern = container.querySelector('#lantern');
    const menu = container.querySelector('#lanternMenu');
    const items = Array.from(menu.querySelectorAll('li'));
    // find page text element to anchor under
    const anchorTarget = document.querySelector('.page-bg > .text');
    function openMenu(){
        // read radius dynamically so CSS changes take effect without reloading JS
        const radius = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--menu-radius')) || 340;
        // compute positions in a circle around lantern
        const count = items.length;
        const startAngle = -90; // start at top
        // distribute evenly around 360 degrees
        const step = 360 / Math.max(1, count);
        // First pass: compute raw positions for all items so we can adjust them collectively
        const computed = [];
        const cssRadius = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--menu-radius')) || 200;
        const baseRadius = Math.min(cssRadius, Math.max(150, window.innerWidth * 0.6));
        const lanternRect = lantern.getBoundingClientRect();
        const padding = 1; // px
        for(let i=0;i<items.length;i++){
            const angle = (startAngle + i * step) * (Math.PI/180);
            let x = Math.cos(angle) * baseRadius;
            let y = Math.sin(angle) * baseRadius * -1; // invert y to match screen coords
            // precompute absolute screen positions for overflow checks
            const itemX = lanternRect.left + lanternRect.width/2 + x;
            const itemY = lanternRect.top + lanternRect.height/2 + y;
            // if item would overflow, pull it back toward center
            const overflowX = Math.max(0, padding - itemX) + Math.max(0, itemX - (window.innerWidth - padding));
            const overflowY = Math.max(0, padding - itemY) + Math.max(0, itemY - (window.innerHeight - padding));
            if(overflowX || overflowY){
                const dist = Math.hypot(x,y) || 1;
                const reduce = Math.max(0, 1 - Math.min(1, (overflowX + overflowY) / dist));
                x = x * reduce;
                y = y * reduce;
            }
            computed.push({x,y,itemX,itemY});
        }

        // Determine bottom-most position index (largest screen Y)
        const posIndicesByY = computed.map((c, idx) => idx).sort((a,b) => computed[a].itemY - computed[b].itemY);
        const bottomPosIndex = posIndicesByY[posIndicesByY.length - 1];

        // Build a lookup of li elements by their data-arch attribute
        const archToLi = {};
        items.forEach(li => {
            const a = li.querySelector('a');
            if(a && a.dataset && a.dataset.arch) archToLi[a.dataset.arch] = li;
        });

        // Prepare assignment: give top two positions to arm64 and arm32 (if present), and bottom position to x86_64
        const assigned = new Map();
        const usedPos = new Set();
        if(archToLi['arm64'] && posIndicesByY.length > 0){ assigned.set(archToLi['arm64'], posIndicesByY[0]); usedPos.add(posIndicesByY[0]); }
        if(archToLi['arm32'] && posIndicesByY.length > 1){ assigned.set(archToLi['arm32'], posIndicesByY[1]); usedPos.add(posIndicesByY[1]); }
        if(archToLi['x86_64'] && typeof bottomPosIndex === 'number'){ assigned.set(archToLi['x86_64'], bottomPosIndex); usedPos.add(bottomPosIndex); }

        // Fill remaining items into remaining positions preserving original order
        for(let i=0;i<items.length;i++){
            const li = items[i];
            if(assigned.has(li)) continue;
            // find next free position from posIndicesByY
            let slot = posIndicesByY.find(idx => !usedPos.has(idx));
            if(slot === undefined) slot = i;
            assigned.set(li, slot);
            usedPos.add(slot);
        }

        // Apply adjustments and set CSS variables for each assigned pair
        const centerIndex = (count - 1) / 2;
        const lateralThreshold = baseRadius * 0.4;
        assigned.forEach((posIdx, li) => {
            let {x,y} = computed[posIdx];
            // If this is bottom-most position, bring it upward
            if(posIdx === bottomPosIndex){ y = y * 0.5; }
            // For left/right items, bring them closer to center
            if(Math.abs(x) > lateralThreshold) x = x * 0.85;
            li.style.setProperty('--x', x.toFixed(2));
            li.style.setProperty('--y', y.toFixed(2));
            // symmetric staggered animation delay (approx center-out by original index)
            const delay = Math.abs(items.indexOf(li) - centerIndex) * 0.04;
            li.style.transitionDelay = (delay) + 's';
        });

        // Explicit override: set the third <li> (index 2) Y coordinate to 150px
        if(items[2]){
            items[2].style.setProperty('--y', '150');
        }
        container.classList.add('open');
        lantern.setAttribute('aria-pressed','true');
    }

    function closeMenu(){
        items.forEach((li,i)=>{ li.style.transitionDelay = ((items.length - i) * 0.02) + 's'; });
        container.classList.remove('open');
        lantern.setAttribute('aria-pressed','false');
        // clear inline positions so re-opening recomputes them and to avoid stuck offsets
        items.forEach(li=>{ li.style.removeProperty('--x'); li.style.removeProperty('--y'); li.style.removeProperty('transition-delay'); });
    }

    function toggle(){
        if(container.classList.contains('open')) closeMenu(); else openMenu();
    }

    lantern.addEventListener('click', function(e){
        toggle();
    });

    // Prevent default focus ring on pointerdown (improves touch visuals)
    lantern.addEventListener('pointerdown', function(e){
        if(e.pointerType === 'touch' || e.pointerType === 'pen'){
            // avoid touch-generated outlines but keep element focus for keyboard
            e.preventDefault();
            lantern.focus({preventScroll:true});
        }
    });

    // close when clicking outside
    document.addEventListener('click', function(e){
        if(!container.contains(e.target)) closeMenu();
    });

    // keyboard support: Space/Enter to toggle; Esc to close
    lantern.tabIndex = 0;
    lantern.addEventListener('keydown', function(e){
        if(e.key === ' ' || e.key === 'Enter'){
            e.preventDefault(); toggle();
        } else if(e.key === 'Escape'){
            closeMenu();
        }
    });

    // Positioning: keep the lantern below the .text element regardless of viewport size
    function positionUnderTarget(){
        if(!anchorTarget) return;
        // get bounding rect of the text block
        const rect = anchorTarget.getBoundingClientRect();
        const rect2 = lantern.getBoundingClientRect();
        // compute center-x of the text block relative to document
        const scrollX = window.scrollX || window.pageXOffset || document.documentElement.scrollLeft;
        const scrollY = window.scrollY || window.pageYOffset || document.documentElement.scrollTop;
        const centerX = rect.left + rect.width/2 + scrollX - rect2.width/2;
        // place lantern a bit below the text block (8px gap)
        const gap = 8;
        const top = rect.bottom + gap + scrollY;
        // set container position (container is absolute)
        container.style.left = centerX + 'px';
        container.style.top = top + 'px';
        // mark anchored so CSS transform: translate(-50%,-50%) is removed
        container.classList.add('anchored');
        // clamp container inside viewport (in case text is near edges)
        requestAnimationFrame(()=>{
            const rect = container.getBoundingClientRect();
            const pad = 8;
            let dx = 0, dy = 0;
            if(rect.left < pad) dx = pad - rect.left;
            if(rect.right > window.innerWidth - pad) dx = (window.innerWidth - pad) - rect.right;
            if(rect.top < pad) dy = pad - rect.top;
            if(rect.bottom > window.innerHeight - pad) dy = (window.innerHeight - pad) - rect.bottom;
            if(dx || dy){
                const curLeft = parseFloat(container.style.left || 0);
                const curTop = parseFloat(container.style.top || 0);
                container.style.left = (curLeft + dx) + 'px';
                container.style.top = (curTop + dy) + 'px';
            }
        });
    }

    // run on load, resize, and scroll to keep lantern in place
    window.addEventListener('load', positionUnderTarget);
    window.addEventListener('resize', positionUnderTarget);
    window.addEventListener('scroll', positionUnderTarget, {passive:true});
    // also position initially if DOM already loaded
    if(document.readyState === 'complete' || document.readyState === 'interactive') positionUnderTarget();

    // optional: detect user arch and highlight likely option
    // Better architecture detection: prefer UA-Client-Hints (UAData) when available, fallback to userAgent regex
    (async function detectArch(){
        try{
            let preferred = null;
            if(navigator.userAgentData && navigator.userAgentData.getHighEntropyValues){
                // ask for 'architecture' if supported
                const hints = await navigator.userAgentData.getHighEntropyValues(['architecture']).catch(()=>({architecture:undefined}));
                const arch = (hints && hints.architecture) || '';
                if(/arm64|aarch64/i.test(arch)) preferred = 'arm64';
                else if(/arm|armeabi/i.test(arch)) preferred = 'arm32';
                else if(/x86_64|amd64|x64/i.test(arch)) preferred = 'x86_64';
                else if(/x86|i386/i.test(arch)) preferred = 'x86';
            }
            if(!preferred){
                const ua = navigator.userAgent || '';
                if(/arm64|aarch64|armv8|armv8l/i.test(ua)) preferred = 'arm64';
                else if(/armeabi|armeabi-v7a|armv7/i.test(ua)) preferred = 'arm32';
                else if(/x86_64|x86-64|x86 64|x64|amd64|win64/i.test(ua)) preferred = 'x86_64';
                else if(/x86|i686|i386/i.test(ua)) preferred = 'x86';
            }
            if(preferred){
                const candidate = menu.querySelector('a[data-arch="'+preferred+'"]');
                if(candidate){
                    candidate.classList.add('preferred');
                    candidate.style.boxShadow = '0 10px 30px rgba(34,197,94,0.18)';
                }
            }
        }catch(e){/* ignore */}
    })();

    // make items clickable and close menu after click
    menu.addEventListener('click', function(e){
        const a = e.target.closest('a');
        if(!a) return;
        // let the link follow, then close
        setTimeout(()=> closeMenu(), 200);
    });

})();
