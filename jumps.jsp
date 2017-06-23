<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.util.HashMap
" %><%@include file="common.jsp" %><%
  String bibcode = request.getParameter("bibcode");
%><!DOCTYPE html>
<html>
  <head>
    <title>Le lemmatiseur du pauvre</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
    <style>
    </style>
  </head>
  <body>
    <%@include file="menu.jsp" %>
      <form method="GET">
        <a href=".">Alix</a>
        <select name="bibcode" onchange="this.form.submit()">
          <%
            seltext( pageContext, bibcode );
          %>
        </select>
        <button>▶</button>
      </form>
    <article>
      <%
        String text = text( pageContext, bibcode );
      int limit = 1000; // limiter les occurrences affichées
      if ( text == null ) {
        if ( bibcode != null && !"".equals( bibcode ))
          out.print( "<p>Le texte "+bibcode+" n’est pas disponible sur ce serveur.</p>\n");
      }
      else {
        Tokenizer toks = new Tokenizer( text );
        HashMap<String,int[]> dico = new HashMap<String,int[]>();
        Occ occ = new Occ();
        int[] entry;
        int pos;
        int dif;
        int last;
        while  ( toks.word( occ ) ) {
          if ( occ.tag().isPun() ) continue;
          if ( occ.tag().isNum() ) occ.orth( "NUM" );
          Entry entry = dico.entry( occ.orth() );
          pos = occ.start();
          last = entry.count2;
          entry.count2 = pos;
          if ( last == 0 ) continue; // première occurrence
          dif = pos - last;
          
        }
      }
      %>
     </article>
  </body>
 </html>
