;(function() {
  'use strict';


  sigma.utils.pkg('sigma.canvas.labels');
  /**
   * This label renderer will just display the label on the right of the node.
   *
   * @param  {object}                   node     The node object.
   * @param  {CanvasRenderingContext2D} context  The canvas context.
   * @param  {configurable}             settings The settings function.
   */
  sigma.canvas.labels.term = function(node, context, settings) {
    if (!node.label || typeof node.label !== 'string')
      return;
    var prefix = settings('prefix') || '';
    // no labels for little nodes
    if (node[prefix + 'size'] < settings('labelThreshold'))
      return;
    context.save();
    var scale = (settings('scale'))?settings('scale'):1;
    // node size relative to global size
    var nodeSize = node[prefix + 'size'] * scale * 0.7;
    // fontSize relative to nodeSize
    var fontSize = (settings('labelSize') === 'fixed') ?
      settings('defaultLabelSize') :
      settings('defaultLabelSize') + settings('labelSizeRatio') * (nodeSize - settings('minNodeSize'));
    // default font ?

    var height = parseInt(fontSize);
    var y = Math.round(node[prefix + 'y'] + nodeSize * 0.6);

    var small = 25;
    context.lineWidth = 1;
    // bg color
    if ( fontSize <= small) {
      context.font = fontSize+'px '+settings('font');
      var width = Math.round(context.measureText(node.label).width);
      var x = Math.round(node[prefix + 'x'] - (width / 2) );
      context.fillStyle = 'rgba(255, 255, 255, 0.6)';
      context.fillRect(x-fontSize*0.2, y - fontSize + fontSize/10, width+fontSize*0.4, height);
    }
    else {
      context.font = settings('fontStyle')+' '+fontSize+'px '+settings('font');
      var width = Math.round(context.measureText(node.label).width);
      var x = Math.round(node[prefix + 'x'] - (width / 2) );
      context.fillStyle = 'rgba(255, 255, 255, 0.2)';
      context.fillRect(x-fontSize*0.2, y - fontSize + fontSize/10, width+fontSize*0.4, height);
    }
    // text color
    if (settings('labelColor') === 'node')
      context.fillStyle = (node.color || settings('defaultNodeColor'));
    else
      context.fillStyle = settings('defaultLabelColor');

    context.fillText( node.label, x, y);

    /* border text ?
    if (settings('labelStrokeStyle') && fontSize > small) {
      context.strokeStyle = settings('labelStrokeStyle');
      context.strokeText(node.label, x, y);
    }
    */
    context.restore();
  };




  window.sigmot = function ( canvas, data, maxNodeSize ) {
    this.canvas = document.getElementById(canvas);


    this.odata = data;
    //
    var height = this.canvas.offsetHeight;
    // adjust maxnode size to screen height
    var scale = Math.max( height, 150) / 700;
    if ( !maxNodeSize ) maxNodeSize = height/25;
    else maxNodeSize = maxNodeSize * scale;
    var width = this.canvas.offsetWidth;

    this.sigma = new sigma({
      graph: data,
      renderer: {
        container: this.canvas,
        type: 'canvas'
      },
      settings: {
        defaultEdgeColor: 'rgba(128, 128, 128, 0.2)',
        defaultNodeColor: "rgba(230, 230, 230, 0.7)",
        edgeColor: "default",
        drawLabels: true,
        defaultLabelSize: 15,
        defaultLabelColor: "rgba(0, 0, 0, 1)",
        labelStrokeStyle: "rgba(255, 255, 255, 0.7)",
        labelThreshold: 1,
        labelSize:"proportional",
        labelSizeRatio: 2,
        font: ' Tahoma, Geneva, sans-serif', // after fontSize
        fontStyle: ' ', // before fontSize
        // height: height,
        // width: width,
        scale : 0.9, // effect of global size on graph objects
        // labelAlignment: 'center', // linkurous only and not compatible with drag node
        sideMargin: 1,
        maxNodeSize: maxNodeSize,
        minNodeSize: 5,
        minEdgeSize: -10,
        maxEdgeSize: maxNodeSize*1.5,

        // minArrowSize: 15,
        // maxArrowSize: 20,
        borderSize: 0,
        outerBorderSize: 3, // stroke size of active nodes
        defaultNodeColor: "#FFF",
        defaultNodeBorderColor: '#000',
        defaultNodeOuterBorderColor: 'rgb(236, 81, 72)', // stroke color of active nodes
        // enableEdgeHovering: true, // bad for memory
        zoomingRatio: 1.3,
        mouseWheelEnabled: false,
        edgeHoverColor: 'edge',
        defaultEdgeHoverColor: '#000',
        edgeHoverSizeRatio: 1,
        edgeHoverExtremities: true,
        doubleClickEnabled: false, // utilisé pour la suppression
      }
    });
    // register noverlap
    var listener = this.sigma.configNoverlap( {
      nodeMargin: 3.0,
      scaleNodes: 1.3
    } );
    // Bind all events:
    listener.bind('start stop interpolate', function(event) {
      console.log( event.type );
    });


    var els = this.canvas.getElementsByClassName('restore');
    if (els.length) {
      this.gravBut = els[0];
      els[0].net = this;
      els[0].onclick = function() {
        this.net.stop(); // stop force and restore button
        this.net.sigma.graph.clear();
        this.net.sigma.graph.read(this.net.odata);
        this.net.sigma.refresh();
      }
    }
    var els = this.canvas.getElementsByClassName('grav');
    if (els.length) {
      this.gravBut = els[0];
      this.gravBut.net = this;
      this.gravBut.onclick = this.grav;
    }
    var els = this.canvas.getElementsByClassName('colors');
    if (els.length) {
      els[0].net = this;
      els[0].onclick = function() {
        var bw = this.net.sigma.settings( 'bw' );
        if (!bw) {
          this.innerHTML = '🌈';
          this.net.sigma.settings( 'bw', true );
        }
        else {
          this.innerHTML = '◐';
          this.net.sigma.settings( 'bw', false );
        }
        this.net.sigma.refresh();
      };
    }
    var els = this.canvas.getElementsByClassName( 'zoomin' );
    if (els.length) {
      els[0].net = this;
      els[0].onclick = function() {
        var c = this.net.sigma.camera; c.goTo({ratio: c.ratio / c.settings('zoomingRatio')});
      };
    }
    var els = this.canvas.getElementsByClassName( 'zoomout' );
    if (els.length) {
      els[0].net = this;
      els[0].onclick = function() {
        var c = this.net.sigma.camera; c.goTo({ratio: c.ratio * c.settings('zoomingRatio')});
      };
    }
    var els = this.canvas.getElementsByClassName( 'turnleft' );
    if (els.length) {
      els[0].net = this;
      els[0].onclick = function() {
        var c = this.net.sigma.camera; c.goTo({ angle: c.angle+( Math.PI*15/180) });
      };
    }
    var els = this.canvas.getElementsByClassName( 'turnright' );
    if (els.length) {
      els[0].net = this;
      els[0].onclick = function() {
        var c = this.net.sigma.camera; c.goTo({ angle: c.angle-( Math.PI*22.5/180) });
      };
    }


    var els = this.canvas.getElementsByClassName( 'mix' );
    if (els.length) {
      this.mixBut = els[0];
      this.mixBut.net = this;
      this.mixBut.onclick = this.mix;
    }
    var els = this.canvas.getElementsByClassName( 'shot' );
    if (els.length) {
      els[0].net = this;
      els[0].onclick = function() {
        this.net.stop(); // stop force
        this.net.sigma.refresh();
        var s =  this.net.sigma;
        var size = prompt("Largeur de l’image (en px)", window.innerWidth);
        sigma.plugins.image(s, s.renderers[0], {
          download: true,
          margin: 50,
          size: size,
          clip: true,
          zoomRatio: 1,
          labels: false
        });
      };
    }

    // resizer
    var els = this.canvas.getElementsByClassName( 'resize' );
    if (els.length) {
      els[0].net = this;
      els[0].onmousedown = function(e) {
        this.net.stop();
        var html = document.documentElement;
        html.sigma = this.net.sigma; // give an handle to the sigma instance
        html.dragO = this.net.canvas;
        html.dragX = e.clientX;
        html.dragY = e.clientY;
        html.dragWidth = parseInt( document.defaultView.getComputedStyle( html.dragO ).width, 10 );
        html.dragHeight = parseInt( document.defaultView.getComputedStyle( html.dragO ).height, 10 );
        html.addEventListener( 'mousemove', sigmot.doDrag, false );
        html.addEventListener( 'mouseup', sigmot.stopDrag, false );
      };
    }

    this.sigma.bind( 'rightClickNode', function( e ) {
      e.data.renderer.graph.dropNode(e.data.node.id);
      e.target.refresh();
    });
    // Initialize the dragNodes plugin:
    sigma.plugins.dragNodes( this.sigma, this.sigma.renderers[0] );
    this.start();
  }
  sigmot.prototype.start = function() {
    if (this.gravBut) this.gravBut.innerHTML = '◼';
    var pars = {
      // slowDown: 1,
      // adjustSizes: true, // NO
      // linLogMode: true, // ??
      // gravity: 0.1, // <1 pour le Tartuffe
      // edgeWeightInfluence: 1, // overlap
      // outboundAttractionDistribution: true, // ?, même avec iterationsPerRender
      // barnesHutOptimize: true, // tartuffe instable
      // barnesHutTheta: 0.1,  // pas d’effet apparent sur si petit graphe
      scalingRatio: 5, // non, pas compris
      // strongGravityMode: true, // instable, nécessaire avec outboundAttractionDistribution
      startingIterations : 100,
      iterationsPerRender : 10, // important
      worker: true,
    };
    this.sigma.startForceAtlas2( pars );
    var net = this;
    setTimeout(function() { net.stop();}, 3000)
  };
  sigmot.prototype.stop = function() {
    this.sigma.killForceAtlas2();
    // this.sigma.startNoverlap();
    if (this.gravBut) this.gravBut.innerHTML = '►';
  };
  sigmot.prototype.grav = function() {
    if ((this.net.sigma.supervisor || {}).running) {
      this.net.sigma.killForceAtlas2();
      // this.sigma.startNoverlap();
      this.innerHTML = '►';
    }
    else {
      this.innerHTML = '◼';
      this.net.start();
    }
    return false;
  };
  sigmot.prototype.mix = function() {
    this.net.sigma.killForceAtlas2();
    if (this.net.gravBut) this.net.gravBut.innerHTML = '►';
    for (var i=0; i < this.net.sigma.graph.nodes().length; i++) {
      this.net.sigma.graph.nodes()[i].x = Math.random()*10;
      this.net.sigma.graph.nodes()[i].y = Math.random()*10;
    }
    this.net.sigma.refresh();
    // this.net.start();
    return false;
  };
  // global static
  sigmot.doDrag = function( e ) {
    this.dragO.style.width = ( this.dragWidth + e.clientX - this.dragX ) + 'px';
    this.dragO.style.height = ( this.dragHeight + e.clientY - this.dragY ) + 'px';
  };
  sigmot.stopDrag = function( e ) {
    var height = this.dragO.offsetHeight;
    var width = this.dragO.offsetWidth;

    this.removeEventListener( 'mousemove', sigmot.doDrag, false );
    this.removeEventListener( 'mouseup', sigmot.stopDrag, false );
    this.sigma.settings( 'height', height );
    this.sigma.settings( 'width', width );
    // var scale = Math.max( height, 150) / 500;
    // this.sigma.settings( 'scale', scale );
    this.sigma.refresh();
  };

})();
