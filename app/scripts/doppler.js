/*
Copyright 2010, Google Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
copyright notice, this list of conditions and the following disclaimer
in the documentation and/or other materials provided with the
distribution.
    * Neither the name of Google Inc. nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

// http://chromium.googlecode.com/svn/trunk/samples/audio/doppler.html

// Events

var producerKAmbientGain = 0.2;
var producerKMainSweepDistance = 30.0;

function producer_set_reverb_impulse_response(producer, url) {
  // Load impulse response asynchronously
  var request = new XMLHttpRequest();
  request.open("GET", url, true);
  request.responseType = "arraybuffer";
  request.onload = function() { 
    // producer.convolver.buffer = context.createBuffer(request.response, false);
  }
  
  request.send();
}

function producer_load_buffer_and_play(cube) {
  console.log(cube,'yolo')
  // Load asynchronously
  var request = new XMLHttpRequest();
  request.open("GET", '/wav/gottomove.mp3', true);
  // request.open("GET", cube.track, true);
  request.responseType = "arraybuffer";

  request.onload = function() {
    console.log(request.response, request) 

    cube.producer.source.buffer = context.createBuffer(request.response, true);
    cube.producer.source.noteOn(0);
  }
  request.send();
}

/**
 * "Animate" the doppler effect
 */
function producer_schedule(producer) {
   // Calculate velocity for doppler effect

   targetPosition = yolo.controls.target
   context.listener.setPosition(targetPosition.x, targetPosition.y, targetPosition.z); 
   // producer.panner.setPosition(targetPosition.x, targetPosition.y, targetPosition.z); 
   
   // Velocity (for doppler effect)
   var kVelocityScale = 50.0;
   var deltaX = kVelocityScale * (targetPosition.x - producer.gLastX);
   var deltaY = kVelocityScale * (targetPosition.y - producer.gLastY);
   var deltaZ = kVelocityScale * (targetPosition.z - producer.gLastZ);
   producer.gLastX = targetPosition.x;
   producer.gLastY = targetPosition.y;
   producer.gLastZ = targetPosition.z;
   
   producer.panner.setVelocity(deltaX, deltaY, deltaZ);
   context.listener.dopplerFactor = producer.dopplerFactor;
}

/**
 * Start doppler demo
 */
 function producer_init(cube) {

     // most importantly i can haz cube.track 

     cube.producer = producer = {}
     producer.cube = cube

     producer.gLastX = 0;
     producer.gLastY = 0;
     producer.gLastZ = 0;

     producer.dopplerFactor = 0.006;


     // producer.source = context.createBufferSource();
     producer.source = context.createMediaElementSource(cube.trackObj)
     // producer.source.mediaElement.volume = 0
     // console.log(producer.source, 'le source', cube);

     producer.masterGainNode = context.createGainNode();
     producer.dryGainNode = context.createGainNode();
     producer.wetGainNode = context.createGainNode();

     producer.panner = context.createPanner();
     producer.convolver = context.createConvolver();

     // Setup initial gains
     producer.masterGainNode.gain.value = 5.0;
     producer.dryGainNode.gain.value = 10.0;
     producer.wetGainNode.gain.value = producerKAmbientGain;

     // Connect dry mix
     producer.source.connect(producer.panner);
     producer.panner.connect(producer.dryGainNode);
     producer.dryGainNode.connect(producer.masterGainNode);
     
     // Connect wet mix
     producer.panner.connect(producer.convolver);
     producer.convolver.connect(producer.wetGainNode);
     producer.wetGainNode.connect(producer.masterGainNode);
     
     // Connect master gain
     producer.masterGainNode.connect(context.destination);
     
     // setReverbImpulseResponse('impulse-responses/tim-warehouse/cardiod-true-stereo-15-8/cardiod-true-stereo-15-8.wav');
     // setReverbImpulseResponse('impulse-responses/house-impulses/dining-living-true-stereo.wav');
     producer_set_reverb_impulse_response(producer, 'wav/s3_r4_bd.wav');

     // producer.source.playbackRate.value = 0.75;

     // copying the position from cube to panner (we'll need to keep this up to date) 
     producer.panner.setPosition(cube.obj.position.x, cube.obj.position.y, cube.obj.position.z);

     // producer.source.loop = true;

     // Load up initial buffer
     // producer_load_buffer_and_play(cube);  
     producer.source.mediaElement.play()

     // Start moving the source
     producer_schedule(producer);
 }
