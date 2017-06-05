<%@ page language="java" contentType="text/html; charset=UTF-8"
  pageEncoding="UTF-8"%>
<%@include file="common.jsp"%>
<%
  request.setCharacterEncoding("UTF-8");
%>
<!DOCTYPE html>
<html>
<head>
<title>Le lemmatiseur du pauvre</title>
<link rel="stylesheet" type="text/css" href="alix.css" />
<style>
</style>
</head>
<body>
  <%@include file="menu.jsp"%>
  <article>
    <h1>
      <a href=".">Alix</a> : <a href="?">recherche avancée</a>
    </h1>
    <ul>
      <li><a href="?q=suis">suis</a> : suis, Suis (forme
        orthographique)</li>
      <li><a href="?q=être">être</a> : est, Est, suis, sera…
        (lemme)</li>
      <li><a href='?q="être"'>"être"</a> : être, Être (forme
        orthographique non lemmatisée)</li>
      <li><a href="?q=mond*">mond*</a> : mondes, Mondain,
        mondanité… (préfixe)</li>
      <li><a href="?q=*ent">*ent</a> : sentent, présentement…
        (suffixe)</li>
      <li><a href="?q=la *">la *</a>: la France, la guerre… (joker)
      </li>
      <li><a href="?q=DET homme">DET homme</a> : un homme, des
        hommes, les hommes (nature grammaticale)</li>
      <li><a href="?q=être ** ADJ">être ** ADJ</a> : est belle, est
        vraiment belle… (trou de moins de 10 mots)</li>
    </ul>
    <form>
      <%
        String q = request.getParameter( "q" ); if (q == null) q ="";
      %>
      <input name="q" value="<%=q.replaceAll( "\"", "&quot;")%>" />
      <button type="submit">chercher</button>
    </form>
    <%
      String dir = pageContext.getServletContext().getInitParameter("globdir");
    if ( dir == null ) dir = pageContext.getServletContext().getRealPath("/WEB-INF/textes/"); 
    if ( !q.isEmpty() ) {
      out.println( "<div class=\"conc\">");
      int left = 20;
      int right = 30;
      OccRoller win = new OccRoller(left, right);
      // loop on folder
      File ls = new File( dir );
      for (final File src : ls.listFiles()) {
        if ( src.getName().startsWith( "." )) continue;
        if ( src.isDirectory() ) continue;
        String text = new String(Files.readAllBytes( Paths.get( src.toString() ) ), StandardCharsets.UTF_8);
        Tokenizer toks = new Tokenizer( text );
        boolean first = true;
        Query query = new Query(q);
        int n = 1;
        int limit = 10; 
        while  ( toks.word( win.add() ) ) {
      if ( !query.test( win.get( 0 ) ) ) continue;
      // first match, display filename
      if ( first ) {
        out.print( "<h4>"+src.getName()+"</h4>" );
        first = false;
      }
      int foundsize = query.foundSize();
      // display a snippet
      out.println( "<p>"+n+" — " );
      for ( int i=-left; i<=right; i++ ) {
        if ( i ==  1 - foundsize ) out.print( "<mark>" );
        win.get( i ).print( new PrintWriter(out) );
        if ( i==0 ) out.println( "</mark>" );
      }
      out.print( "</p>" );
      n++;
      if ( n == limit ) {
        break;
      }
        }
      }
      out.println("</div>");
    }
    %>
  </article>
</html>