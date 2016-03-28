class Game extends Fz2D.Game
  w: window.innerWidth
  h: window.innerHeight
  bg: '#3F7CB6'

  assets:
    sprites: 'sprites.atlas'
    sounds:
      failure: 'failure.ogg'
      success: 'success.ogg'
 
  plugins: [
    Fz2D.Plugins.GitHub,
    Fz2D.Plugins.Stats,
    Fz2D.Plugins.GoogleAnalytics
  ]

  ga:
    id: 'UA-3042007-2'

  github:
    username: 'icebreaker'
    repository: 'menhir'

  sound:
    volume: 50

  onload: (game) ->
    assets = game.assets
    sounds = assets.sounds
    scene = game.scene

    sprites = assets.sprites

    volume = game.storage.get('volume', game.sound.volume)

    for _, sound of sounds
      sound.setVolume(volume)

    cx = (game.w - (3 * 68)) >> 1
    cy = (game.h - (9 * 68)) >> 1

    textures = []

    for i in [0..24]
      textures.push(sprites.getTexture("building#{i}"))

    menhir_texture = sprites.getTexture('menhir')

    random = new Fz2D.Random()

    tiles = scene.add(new Fz2D.Group(0, 0, game.w, game.h))

    for y in [0..7]
      for x in [0..7]
        v = Fz2D.Iso.to(x * 68, y * 68)

        tile = tiles.add(new Fz2D.Entity(textures[random.next(textures.length)], cx + v.x, cy + v.y, 'building'))
        tile.addAnimation('menhir', menhir_texture)
        tile.bounds.set(38, 16, 61, 59)
        tile.xx = x
        tile.yy = y

    menhir_tile = tiles.at(random.next(8) + (random.next(8) << 3))
    menhir_tile.play('menhir')

    selected = null

    # SO, SO, DIRTY !!! Oh TUTORIALS !!!
    selected_tile = tiles.find((tile) ->
      Fz2D.distSqr(menhir_tile, tile) == 23120
    )

    arrow = scene.add(new Fz2D.Entity(sprites.getTexture('arrow_down'), menhir_tile.x + 18, menhir_tile.y - 68))
    arrow.kill()

    arrow_selected = scene.add(new Fz2D.Entity(sprites.getTexture('arrow_down'), selected_tile.x + 18, selected_tile.y - 68))

    timeout = scene.add(new Fz2D.Timeout(2000, true))
    timeout.onend = () ->
      if arrow_selected.exists
        arrow_selected.kill()
        arrow.reset()
        timeout.reset()
      else
        timeout.loop = false
        arrow.kill()
    timeout.reset()

    checkbox = scene.add(new Fz2D.Gui.Checkbox(20,  20, sprites.getTexture('audio_on'), sprites.getTexture('audio_off')))
    checkbox.onclick = () ->
      if game.storage.get('volume', game.sound.volume) == 0
        volume = game.sound.volume
      else
        volume = 0

      game.storage.set('volume', volume)

      for _, sound of sounds
        sound.setVolume(volume).stop()

    checkbox.play('unchecked') if volume == 0

    button = scene.add(new Fz2D.Gui.Button(120, 20, sprites.getTexture('restart')))
    button.onclick = () ->
      selected.alpha = 1.0 if selected?
      selected = null

      tiles.each((tile) ->
        tile.addAnimation('building', textures[random.next(textures.length)])
        tile.play('building')
      )

      tiles.at(random.next(8) + (random.next(8) << 3)).play('menhir')

    game.input.mouse.hide()

    mouse = scene.add(new Fz2D.Gui.Mouse(sprites.getTexture('cursor_hand')))
    mouse.onclick = () ->
      tile = tiles.find(Fz2D.contains, mouse.position)
      if not tile?
        selected.alpha = 1.0 if selected?
        selected = null
        return

      if selected?
        x = tile.xx - selected.xx
        y = tile.yy - selected.yy

        if tile.is('menhir') and (Math.abs(x) ^ Math.abs(y)) == 2
          xx = selected.xx + (x >> 1)
          yy = selected.yy + (y >> 1)

          between_tile = tiles.at(xx + yy * 8)

          if between_tile.is('building')
            between_tile.play('menhir')
            selected.play('menhir')
            tile.play('building')
            assets.sounds.success.play()
          else
            assets.sounds.failure.play()
        else
          assets.sounds.failure.play()

        selected.alpha = 1.0
        selected = null
      else if tile.is('building')
        selected = tile
        selected.alpha = 0.7

Game.run()
