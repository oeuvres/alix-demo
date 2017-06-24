<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%!

private void sigma2( List<SimRow> sims, boolean stop ) throws IOException
{
  int edge = 0;
  final int children1 = 30;
  final int children2 = 10;
  int child1 = 0;
  DicFreq dic = veks.dic();
  HashMap<Integer, int[]> nodes = new HashMap<Integer, int[]>();
  int rootcode = -1;
  printer.println( "{" );
  printer.println( "  edges: [" );
  for ( SimRow node1:sims ) {
    if ( stop && node1.code < veks.stopoffset ) continue;
    if ( child1 == 0 ) {
      nodes.put( node1.code, new int[]{ ROOT, dic.count( node1.code ) } );
      rootcode = node1.code;
      child1++;
      continue;
    }
    nodes.put( node1.code, new int[]{ SIM, dic.count( node1.code ) } );
    printer.println( "    { id:'e"+edge+"', source:'n"+rootcode+"', target:'n"+node1.code+"' }, "
      +"// "+dic.label( rootcode )+" "+dic.label( node1.code ) );
    edge++;
    int child2 = 0;
    List<SimRow> sims2 = veks.sims( node1.code );
    for ( SimRow node2:sims2 ) {
      if ( child2 == 0 ) {
        child2++;
        continue;
      }
      if ( stop && node2.code < veks.stopoffset ) continue;
      if ( !nodes.containsKey( node2.code )) nodes.put( node2.code, new int[]{ SIM2SIM, dic.count( node2.code ) } );
      printer.println( "    { id:'e"+edge+"', source:'n"+node1.code+"', target:'n"+node2.code+"' }, "
          +"// "+dic.label( node1.code )+" "+dic.label( node2.code ) );
      edge++;
      if ( ++child2 >= children2) break;
    }
    if ( ++child1 >= children1) break;
  }
  printer.println( "  ]," );
  sigmanodes( nodes );
  printer.print( "}" );
}%><%@include file="vekshare.jsp" 
%>
<style>
#form { position: absolute; z-index: 3; }
#graph { height: 99%; } 
</style>
<body>
<%
  if ( request.getParameter( "iframe" ) == null ) form( corpusdir, corpus, term );
this.veks = (DicVek)application.getAttribute( corpus );
if ( veks != null ) {
  boolean stopfilter = true;
  String href = "?corpus="+corpus+"&amp;term=";
  List<SimRow> sims = veks.sims( term );
  if ( sims != null ) {
    graphdiv( "graph" );
    out.println( "<script>" );
    out.println( "(function () {" );
    out.print( "var data =");
    sigma2( sims, stopfilter );
    out.println( "; var graph = new sigmot( 'graph', data ); ");
    out.println( " })();" );
    out.println( "</script>" );
  }
}
%>
  </body>
</html>