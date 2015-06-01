ComponentTile = require './ComponentTile.coffee'
ModelTile = require '../models/ModelTile.coffee'

R = React.DOM

Tiles = React.createClass
    displayName: 'Tiles'
    getInitialState: ->
        all: []

    render: ->
        tiles = this.state.all.map (item, index) =>
            React.createElement ComponentTile, {
                key: index
                ref: item.model.uid
                tile: item
            }

        R.ul {
            id: 'board'
        }, tiles

    componentDidMount: ->
        collection = @
        @model = class Model extends ModelTile
            clear: ->
                super()
                collection.clearNeighbors @
                collection.moveUpdate()

            toggleFlag: ->
                super()
                collection.moveUpdate()

            click: ($event) ->
                collection.noMineFirstClick @
                super $event

                # Rerender `this` tile
                tileRef = collection.refs[@model.uid]
                if (tileRef)
                    tileRef.forceUpdate()

        @newGame()

    newGame: ->
        @reset()
        @sizeY = 4
        @sizeX = 7
        @numOfMines = 5

        for y in [0..@sizeY - 1]
            for x in [0..@sizeX - 1]
                attrs = {
                    x   : x
                    y   : y
                }
                @add attrs

        for mineNum in [1..@numOfMines]
            tile = @randomSafeTile()
            tile.model.isMine = true

        @tallyMines()
        @gameUpdate()

    # Finds an empty tile and marks it as a mine if no tiles
    # have yet to be clicked AND the given tile is a mine
    noMineFirstClick: (tile) ->
        if @numOfClears is 0 and tile.model.isMine is true
            tile.model.isMine = false
            @randomSafeTile().model.isMine = true
            @tallyMines()

        return tile

    add: (model) ->
        tiles = @state.all
        tile = new @model model
        tiles.push tile
        @setState all: tiles
        tile

    handleTileClick: (event, index) ->

    reset: ->
        @setState(all:[])
        @


    get : (attrs) ->
        return @getAll(attrs)[0]

    getAll : (attrs) ->
        matches = []
        if !attrs
            return @state.all

        for tile in @state.all
            numOfAttrs = 0
            numOfMatchedAttrs = 0
            for key, val of attrs
                numOfAttrs++
                if tile.model[key] is val
                    numOfMatchedAttrs++

            if numOfMatchedAttrs is numOfAttrs
                matches.push tile

        return matches

    randomSafeTile : () ->
        findAttrs =
            isClear : false
            isMine  : false

        safeTiles = @getAll findAttrs
        randomIndex = Math.floor Math.random() * safeTiles.length
        return safeTiles[ randomIndex ]

    tallyMines : () ->
        for tile in @state.all
            neighborMines = 0
            for adjacentTile in tile.adjacentTiles
                neighborX = tile.model.x + adjacentTile[0]
                neighborY = tile.model.y + adjacentTile[1]
                neighborAttrs = {
                    isMine  : true
                    x       : neighborX
                    y       : neighborY
                }
                neighborMine = this.get(neighborAttrs)
                if neighborMine isnt undefined
                    neighborMines++
            tile.model.adjacentMines = neighborMines

    gameUpdate : ->
        @x = Math.max.apply @, @state.all.map (tile) ->
            tile.model.x

        @y = Math.max.apply @, @state.all.map (tile) ->
            tile.model.y

        # Offset by 1 to account for 0 index
        @x = @x--
        @y = @y--


        @numOfMines = 0
        for tile in @state.all
            if tile.model.isMine is true
                @numOfMines++

        @moveUpdate()

    moveUpdate : ->
        this.loss    = false
        this.win     = false
        this.numOfClears = 0
        this.numOfFlags  = 0

        for tile in @state.all
            # Cleared Tiles
            if tile.model.isClear == true
                this.numOfClears++

            # Flagged Tiles
            if tile.model.isFlagged == true
                this.numOfFlags++

            # Check Game Loss
            if tile.model.isMine == true && tile.model.isClear == true
                this.loss = true

        # Check Game Win
        if this.loss == false && @state.all.length - this.numOfMines - this.numOfClears == 0
            this.win = true

    clearNeighbors : (tile) ->
        shouldClearNeighbors = tile.model.adjacentMines is 0 and tile.model.isMine is false
        if shouldClearNeighbors
            for adjacentTile in tile.adjacentTiles
                neighbor = @get(
                    x : tile.model.x + adjacentTile[0]
                    y : tile.model.y + adjacentTile[1]
                )

                shouldClearNeighbor = (
                    neighbor and
                    neighbor.model.isClear is false and
                    neighbor.model.isMine is false
                )

                if shouldClearNeighbor
                    neighbor.click()

        @

module.exports = Tiles