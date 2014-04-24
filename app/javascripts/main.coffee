window.cl = (o) ->
  console.debug(o)

class Space
  distance: (a, b) ->
    return Math.abs(Math.sqrt(Math.pow(a.x - b.x, 2) + Math.pow(a.y - b.y, 2) + Math.pow(a.z - b.z, 2)))

class Vector
  constructor: (@x = 0, @y = 0, @z = 0) ->

class Object
  constructor: (@_name) ->
    @_position = new Vector()

  getPosition: () ->
    @_position

  setPosition: (@_position) ->

  getName: ->
    @_name

  draw: ->
    s = $('<section data-bind="' + @_name + '">')
    s.append($('<h2>' + @_name + ':</h2>'))
    _.each ['x', 'y', 'z'], (k) =>
      l = $('<label>')
      l.html(k + ': ')
      s.append(l)

      i = $('<input type="text">')
      i.attr('name', k)
      i.val(@_position[k])
      s.append(i)

    $('.container').append(s)


class Producer extends Object

  constructor: (name) ->
    super name
    @out = context.createOscillator()
  
  start: ->
    @out.noteOn(0)

  stop: ->
    @out.noteOff(0)

  loop: ->
    # nothing here
    # cl('loop. producer')

class Listener extends Object
  producers: []

  constructor: (name) ->
    super name

  listen: (producer) ->
    gainNode = context.createGainNode()
    producer.out.connect(gainNode)

    @producers.push
      producer: producer
      gainNode: gainNode

    gainNode.connect(context.destination)

  loop: ->
    # calculate the distance between itself and all the producers adjusting their gains acordingly
    _.each @producers, (o) =>
      distance = space.distance(@getPosition(), o.producer.getPosition())
      value = 1 / Math.pow(distance, 2)
      o.gainNode.gain.value = if value > 1 then 1 else value
      $('.gain').html(o.gainNode.gain.value)

class World
  constructor: ->
    @buildCam()
    @buildEls()
    @clock = new THREE.Clock()
    @allowedToRender = true
    
  buildCam: ->
    @camera = new THREE.PerspectiveCamera( 35, window.innerWidth / window.innerHeight/2, 1, 100 )
    @camera.position.set( 0, 0, 0 )
    
    # DESSAU - listener
    @listener = new Listener('listener')


    # @camera.element.webkitRequestPointerLock()
    # @controls = new THREE.FlyControls(@camera)
    @controls = new THREE.FirstPersonControls(@camera)
    @controls.movementSpeed = 2000
    @controls.lookSpeed = 0.039
    @controls.lookVertical = false #// Don't allow the player to look up or down. This is a temporary fix to keep people from flying
    @controls.noFly = true #// Don't allow hitting R or F to go up or down
    @controls.activeLook = true
    # @controls.rollSpeed = 0.205;
    # @controls.lookVertical = true
    @



  makeCube: (size, pos, trackUrl, trackData) ->

    wrapEl = document.createElement( 'section' )
    wrapEl.style.width = '400px'
    wrapEl.style.height = '400px'
    wrapEl.classList.add 'box_wrap'

    # audioEl = "<audio src='#{trackUrl}' />"
    audioEl = new Audio
    audioEl.src = trackUrl
    audioEl.loop = 'loop'
    audioEl.preload = 'none'
    # audioEl.autoplay = 'true'



    $(wrapEl).append audioEl

    cubeWrap = new THREE.CSS3DObject(wrapEl)

    @centerVector = new THREE.Vector3()


    faces = []

    for i in [0...6]

      # img = new Image()
      # console.log trackData.object
      face = document.createElement( 'div' )

      title = trackData.object.metadata.title
      artist = if trackData.object.metadata.artist? then trackData.object.metadata.artist.name else '' 
      tmpl = "<h1>#{artist}</h1><h2>#{title}</h2>"
      $(face).append tmpl
      if trackData.object.images?
        face.style.background = "url(#{trackData.object.images.medium.url})"

      # face.appendChild img
      face.style.width = size * 2 + "px"
      face.style.height = size * 2 + "px"
      face.classList.add 'box_face'
      # faces[i].element.style.background = "hsl(#{i*20}, 50%, 50%)"


      # create the 3dobject
      faces[i] = new THREE.CSS3DObject(face)

      # add to parent 3dobject
      cubeWrap.add faces[i]
    

    faces[2].position.z = faces[3].position.x = faces[5].position.y = -size
    faces[0].position.z = faces[1].position.x = faces[4].position.y = size


    for i in [0..faces.length-1]
      faces[i].lookAt @centerVector

    # cubeBase.add cubeWrap
    cubeWrap.position.set(pos.x, pos.y, pos.z)


    # # DESSAU - make it sing
    # producer = new Producer('producer')
    # gainNode = context.createGainNode()
    # producer.out.connect(gainNode)
    # gainNode.connect(context.destination)
    # producer.start()



    # add to scene and store 
    @scene.add cubeWrap

    _.delay (=>

      cubeObj = {
        obj: cubeWrap
        track: trackUrl
        trackObj: $(audioEl)[0]
        trackData: trackData
      }


      @cubez.push cubeObj

      # _.delay (=>
      producer_init cubeObj
      # ), 100
      # console.log @cubez

    ), 10



  buildEls: ->
    @counter = 0 
    @scene = new THREE.Scene()
    # console.log shuffler, 'is shuffler ther?'

    tracks = shuffler.fetchChannel 'electronic', (tracks) =>
      goodTracks = _.filter tracks, (t, i) =>
        t.object.stream.platform is 'soundcloud'

      @tracks = goodTracks
      # console.log @tracks



      # console.log 'i haz tracks?', tracks

      @producers = []

      cubeCount = 10
      @cubez = []


      # create #{count} amount of cubes on coords at certain size
      for track in @tracks
      # track = @tracks[0]
        trackUrl = track.object.stream.url + "?client_id=c280d0c248513cfc78d7ee05b52bf15e"
        size = (Math.random() * 100) + 350
        coords = 
          x: (Math.random() * 20000) + 200
          y: Math.random() * 5
          z: (Math.random() * 20000) + 200
        @makeCube size,coords, trackUrl, track
        


    # prep renderer
    @renderer = new THREE.CSS3DRenderer()
    @renderer.setSize( window.innerWidth, window.innerHeight)
    @renderer.domElement.style.position = 'absolute'
    @renderer.domElement.style.top = 0
    $('body').append @renderer.domElement


    # let it breath, start game loop
    _.delay (=>
      @animate()
    ), 200
    
 
  haveFun: ->
    if @cubez?.length
      for cube in @cubez
        # cube.obj.rotation.x +=0.003# * Math.random() 
        # cube.obj.rotation.y +=0.002
        # cube.obj.rotation.z +=0.001

        cube.obj.rotation.x +=0.003# * Math.random() 
        cube.obj.rotation.y +=0.002
        cube.obj.rotation.z +=0.001



        # distance = space.distance(@controls.target, cube.obj.position)
        producer_schedule( cube.producer )

        # crazyness
        # value = (1 / Math.pow((distance), 2)) * 10000
        # value = 1000000 / Math.pow(@controls.target.distanceTo(cube.obj.position), 2)
        # cube.gainNode.gain.value = if value > 1 then 1 else value
        # if @counter < 200

        #   # console.log value, distance, @controls.target, cube.obj.position
        #   @counter++

  animate: ->
    # unless not @allowedToRender
    requestAnimationFrame( world.animate )


    world.haveFun()

    delta = world.clock.getDelta()
    world.controls.update(delta)
    world.renderer.render( world.scene, world.camera )











# class Player

#   constructor: ->
#     @

#   loadBufferAndPlay: (url) ->
  
#   # Load asynchronously
#   request = new XMLHttpRequest()
#   request.open "GET", url, true
#   request.responseType = "arraybuffer"
#   request.onload = ->
#     source.buffer = context.createBuffer(request.response, true)
#     source.noteOn 0






class Shuffler

  root: "http://api.shuffler.fm/v1/"


  constructor: ->
    @



  fetchChannel: (channel, callback) ->
    url = @channel_url channel

    req = $.getJSON url, (res) ->
      # console.log 'succless', res

      if callback? then callback res
      res


  encodeParams: (params) ->
    defaults =
      "api-key": "zlspn5imm91ak2z7nk3g" # PRO:  user_id: 26586 (adrian)
      # "api-key": "api-test-key" # PRE
    $.extend(params, defaults)
    "?" + $.param(params)

  channel_url: (key, params = {}) ->
    @root + 'channels/' + escape(key) + @encodeParams(params) + "&callback=?"

  genres_url: (params = {})->
    @root + 'genres' + @encodeParams(params)




(->
  window.shuffler = new Shuffler()
  window.space = new Space()
  window.context = new webkitAudioContext()
  window.world = new World()

  # setTimeout ( ->
  #   world.animate()
  #   # world.controlRendering 'start'
  #   # console.log 'world'
  # ), 500

)()
