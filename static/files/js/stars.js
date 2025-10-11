// stars.js — spawn small rotating stars from top that fall and fade
(function(){
  // Reduce default density on mobile for performance
  const isSmallScreen = window.matchMedia && window.matchMedia('(max-width:600px)').matches;
  const maxStars = isSmallScreen ? 60 : 300;
  const spawnInterval = isSmallScreen ? 180 : 50; // ms
  // place stars into a dedicated layer if available
  let container = document.querySelector('.stars-layer');
  if(!container){
    const pageBg = document.querySelector('.page-bg');
    if(pageBg){
      container = document.createElement('div');
      container.className = 'stars-layer';
      pageBg.insertBefore(container, pageBg.firstChild);
    } else {
      container = document.body;
    }
  }

  function rand(min, max){ return Math.random() * (max - min) + min }

  function createStar(){
    const s = document.createElement('div');
    s.className = 'falling-star';
  const size = isSmallScreen ? rand(14, 26) : rand(20, 38); // px
    s.style.width = s.style.height = size + 'px';

    s.style.left = rand(2, 98) + '%';
    s.style.top = (-40 + rand(0,40)) + 'px'; // start slightly above view
    s.style.opacity = String(rand(0.75,1));

  // rotation duration and fall duration
  const rot = isSmallScreen ? rand(3,8) : rand(4,12);
  const fall = isSmallScreen ? rand(3,5) : rand(3.5,7);
  // rotate via CSS animation, move via JS transition for reliable motion
  s.style.animation = `star-rotate ${rot}s linear infinite`;
  s.style.willChange = 'transform, opacity';
  // set initial transform (no translate) then transition to end position
  s.style.transform = `translateY(0px) rotate(${rand(0,360)}deg)`;

    container.appendChild(s);

    // force reflow then start the transform transition
    requestAnimationFrame(()=>{
      // distance to move: viewport height + extra buffer
      const distance = window.innerHeight + 300;
      // use transform-only transition (hardware-accelerated)
      s.style.transition = `transform ${fall}s linear, opacity ${fall}s linear`;
      // rotate a bunch while falling
      const extraRot = 360 * rand(1,3);
      s.style.transform = `translateY(${distance}px) rotate(${extraRot}deg)`;
    });

    // cleanup after animation
    setTimeout(()=>{ s.remove() }, Math.max(8000, fall*1000 + 1200));
  }

  // spawn periodically but keep count bounded
  // Use an RAF-based spawner to better cooperate with browser paint loop
  function spawnLoop(){
    const current = document.querySelectorAll('.falling-star').length;
    if(current < maxStars){ createStar(); }
    setTimeout(()=> requestAnimationFrame(spawnLoop), spawnInterval);
  }
  spawnLoop();
})();
