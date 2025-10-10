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
        items.forEach((li, i)=>{
            const angle = (startAngle + i * step) * (Math.PI/180);
            const x = Math.cos(angle) * 200;
            const y = Math.sin(angle) * 200 * -1; // invert y to match screen coords
            li.style.setProperty('--x', x.toFixed(2));
            li.style.setProperty('--y', y.toFixed(2));
            // symmetric staggered animation delay (center-out)
            const centerIndex = (count - 1) / 2;
            const delay = Math.abs(i - centerIndex) * 0.04;
            li.style.transitionDelay = (delay) + 's';
        });
        container.classList.add('open');
        lantern.setAttribute('aria-pressed','true');
    }

    function closeMenu(){
        items.forEach((li,i)=>{ li.style.transitionDelay = ((items.length - i) * 0.02) + 's'; });
        container.classList.remove('open');
        lantern.setAttribute('aria-pressed','false');
    }

    function toggle(){
        if(container.classList.contains('open')) closeMenu(); else openMenu();
    }

    lantern.addEventListener('click', function(e){
        toggle();
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
    }

    // run on load, resize, and scroll to keep lantern in place
    window.addEventListener('load', positionUnderTarget);
    window.addEventListener('resize', positionUnderTarget);
    window.addEventListener('scroll', positionUnderTarget, {passive:true});
    // also position initially if DOM already loaded
    if(document.readyState === 'complete' || document.readyState === 'interactive') positionUnderTarget();

    // optional: detect user arch and highlight likely option
    try{
        // naive check from navigator.userAgent
        const ua = navigator.userAgent || '';
        let preferred = null;
        if(/arm64|aarch64|armv8|armv8l/i.test(ua)) preferred = 'arm64';
        else if(/armeabi|armeabi-v7a|armv7/i.test(ua)) preferred = 'arm32';
        else if(/x86_64|x86-64|x86 64|x64|amd64|win64/i.test(ua)) preferred = 'x86_64';
        else if(/x86|i686|i386/i.test(ua)) preferred = 'x86';
        if(preferred){
            const candidate = menu.querySelector('a[data-arch="'+preferred+'"]');
            if(candidate){
                // add a preferred class for CSS styling
                candidate.classList.add('preferred');
                // ensure visual emphasis even before opening
                candidate.style.boxShadow = '0 10px 30px rgba(34,197,94,0.18)';
            }
        }
    }catch(e){}

    // make items clickable and close menu after click
    menu.addEventListener('click', function(e){
        const a = e.target.closest('a');
        if(!a) return;
        // let the link follow, then close
        setTimeout(()=> closeMenu(), 200);
    });

})();
