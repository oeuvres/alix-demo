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
    if (settings('labelColor') === 'node') {
      context.fillStyle = (node.color || settings('defaultNodeColor'));
    }
    else {
      context.fillStyle = settings('defaultLabelColor');
    }

    context.fillText( node.label, x, y);

    /* border text ?
    if (settings('labelStrokeStyle') && fontSize > small) {
      context.strokeStyle = settings('labelStrokeStyle');
      context.strokeText(node.label, x, y);
    }
    */
    context.restore();
  };




  window.sigmot = function ( id, data, maxNodeSize ) {
    alert( "coucou ?" );
    this.canvas = document.getElementById( id );


    this.odata = data;
    //
    var height = this.canvas.offsetHeight;
    // adjust maxnode size to screen height
    var scale = Math.max( height, 150) / 700;
    if ( !maxNodeSize ) maxNodeSize = height/25;
    else maxNodeSize = maxNodeSize * scale;
    var width = this.canvas.offsetWidth;


    this.sigma = new sigma({
      id: id,
      graph: data,
      renderer: {
        container: this.canvas,
        type: 'canvas'
      },
      settings: {
        defaultNodeColor: "rgba(128, 128, 128, 0.9)",
        defaultEdgeColor: 'rgba(192, 192, 192, 0.3)',
        edgeColor: "default",
        drawLabels: true,
        defaultLabelSize: 10,
        defaultLabelColor: "rgba( 0, 0, 0, 0.8)",
        // labelStrokeStyle: "rgba(255, 255, 255, 0.7)",
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
        minNodeSize: 5,
        maxNodeSize: maxNodeSize,
        minEdgeSize: -1,
        maxEdgeSize: maxNodeSize,

        // minArrowSize: 15,
        // maxArrowSize: 20,
        borderSize: 1,
        outerBorderSize: 3, // stroke size of active nodes
        defaultNodeColor: "#FFFFFF",
        defaultNodeBorderColor: '#000000',
        defaultNodeOuterBorderColor: 'rgb(236, 81, 72)', // stroke color of active nodes
        zoomingRatio: 1.3,
        mouseWheelEnabled: false,
        edgeHoverColor: 'edge',
        defaultEdgeHoverColor: '#000000',
        doubleClickEnabled: false, // utilisé pour la suppression
        /*
        enableEdgeHovering: true, // bad for memory
        edgeHoverSizeRatio: 1,
        edgeHoverExtremities: true,
        */
      }
    });
    var s = this.sigma;
    sigma.layouts.fruchtermanReingold.configure( s, {
      autoArea: true,
      area: 1,
      gravity: 0.5,
      speed: 0.1,
      iterations: 1000
    } );

    s.bind( "doubleClickNode", function( e ) {
      window.location.href = window.location.href.replace( /term=[^&]+/, "term="+e.data.node.label );
    });
    this.sigma.bind( 'rightClickNode', function( e ) {
      e.data.renderer.graph.dropNode(e.data.node.id);
      e.target.refresh();
    });
    s.bind( "overNode", function( e ) {
      if ( this.workOver ) return;
      this.workOver = true;
      var center= e.data.node;
      var nodes = e.data;
      var neighbors = {};
	    s.graph.edges().forEach( function(e) {
        if ( e.source != center.id && e.target != center.id ) {
          e.hidden = true;
          return;
        }
        neighbors[e.source] = 1;
        neighbors[e.target] = 1;
	    });
      s.graph.nodes().forEach( function(n) {
	      if( neighbors[n.id] ) {
          n.hidden = 0;
	      } else {
          n.hidden = 1;
	      }
	    });
      s.refresh( );
      this.workOver = false;
    } ).bind('outNode', function() {
      if ( this.workOut ) return;
      this.workOut = true;
      s.graph.edges().forEach( function(e) {
	      e.hidden = 0;
	    } );
      s.graph.nodes().forEach( function(n) {
	      n.hidden = 0;
	    });
      s.refresh();
      this.workOut = false;
	  } );

    var els = this.canvas.getElementsByClassName('restore');
    if (els.length) {
      // this.atlas2But = els[0];
      els[0].net = this;
      els[0].onclick = function() {
        this.net.stop(); // stop force and restore button
        this.net.sigma.graph.clear();
        this.net.sigma.graph.read(this.net.odata);
        this.net.sigma.refresh();
      }
    }
    var els = this.canvas.getElementsByClassName('FR');
    if (els.length) {
      this.FRBut = els[0];
      this.FRBut.net = this;
      this.FRBut.onclick = function() {
        sigma.layouts.fruchtermanReingold.start( s );
      }
    }
    var els = this.canvas.getElementsByClassName('atlas2');
    if (els.length) {
      this.atlas2But = els[0];
      this.atlas2But.net = this;
      this.atlas2But.onclick = this.atlas2;
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
        var size = prompt( "Largeur de l’image (en px)", window.innerWidth );
        sigma.plugins.image(s, s.renderers[0], {
          download: true,
          margin: 50,
          size: size,
          clip: true,
          zoomRatio: 1,
          background: "#FFFFFF",
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

    // Initialize the dragNodes plugin:
    sigma.plugins.dragNodes( this.sigma, this.sigma.renderers[0] );
    this.start();
  }
  sigmot.prototype.start = function() {
    if (this.atlas2But) this.atlas2But.innerHTML = '◼';
    var pars = {
      gravity: 1, // <1 pour le Tartuffe
      worker: true, // OUI !
      // linLogMode: true, // ??
      // outboundAttractionDistribution: true, // ?, même avec iterationsPerRender
      // barnesHutOptimize: true, // tartuffe instable
      // barnesHutTheta: 0.1,  // pas d’effet apparent sur si petit graphe
      scalingRatio: 4, // utile parfois
      // strongGravityMode: true, // instable, nécessaire avec outboundAttractionDistribution
      startingIterations : 100,
      iterationsPerRender : 100, // important
      // slowDown: 1, // NON
      // adjustSizes: true, // NO
      // edgeWeightInfluence: 0.1, // éparpille, bof
    };
    this.sigma.startForceAtlas2( pars );
    var net = this;
    setTimeout(function() { net.stop();}, 3000)
  };
  sigmot.prototype.stop = function() {
    this.sigma.killForceAtlas2();
    // this.sigma.startNoverlap();
    if (this.atlas2But) this.atlas2But.innerHTML = '►';
  };
  sigmot.prototype.atlas2 = function() {
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
    if (this.net.atlas2But) this.net.atlas2But.innerHTML = '►';
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
