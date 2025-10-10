// stars.js — spawn small rotating stars from top that fall and fade
(function(){
  const maxStars = 500;
  const spawnInterval = 50; // ms
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
    const size = rand(20, 38); // px
    s.style.width = s.style.height = size + 'px';

    s.style.left = rand(2, 98) + '%';
    s.style.top = (-40 + rand(0,40)) + 'px'; // start slightly above view
    s.style.opacity = String(rand(0.75,1));

    // rotation duration and fall duration
    const rot = rand(4,12);
    const fall = rand(3.5,7);
    // rotate via CSS animation, move via JS transition for reliable motion
    s.style.animation = `star-rotate ${rot}s linear infinite`;
    s.style.willChange = 'transform';

    // set initial transform (no translate) then transition to end position
    s.style.transform = `translateY(0px) rotate(${rand(0,360)}deg)`;

    container.appendChild(s);

    // force reflow then start the transform transition
    requestAnimationFrame(()=>{
      // distance to move: viewport height + extra buffer
      const distance = window.innerHeight + 300;
      s.style.transition = `transform ${fall}s linear`;
      // rotate a bunch while falling
      const extraRot = 360 * rand(1,3);
      s.style.transform = `translateY(${distance}px) rotate(${extraRot}deg)`;
    });

    // cleanup after animation
    setTimeout(()=>{ s.remove() }, Math.max(8000, fall*1000 + 2000));
  }

  // spawn periodically but keep count bounded
  let active = 0;
  setInterval(()=>{
    const current = document.querySelectorAll('.falling-star').length;
    if(current < maxStars){ createStar() }
  }, spawnInterval);
})();
