<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
site.oeuvres.fr.Lexik,
site.oeuvres.fr.Tokenizer,
site.oeuvres.fr.Occ
" %>
<%
request.setCharacterEncoding("UTF-8");
%>
<!DOCTYPE html>
<html>
  <head>
    <title>Le lemmatiseur du pauvre</title>
    <link rel="stylesheet" type="text/css" href="http://svn.code.sf.net/p/obvil/code/theme/obvil.css" />
  </head>
  <body>
    <article id="article">
      <h1><a href=".">Alix</a> : Le lemmatiseur du pauvre</h1>
      <p>
Ce lemmatiseur n’a aucune intelligence syntaxique. Pour une forme graphique, il donne le lemme le plus fréquent.
Obligatoirement, ce lemmatiseur fera des erreurs, mais ces erreurs seront assez faciles à prévoir,
contrairement à des approches statistiques plus élaborées. Par exemple, la forme graphique “est” sera toujours
considérée comme l’auxilliaire “être”, aucun supposition ne sera tentée pour distinguer le passé composé,
une forme passive, ou un emploi en copule. “L’est”, point cardinal sera aussi étiqueté auxilliaire “être”. Cette approche simpliste
s’avère utilement prudente lorsque l’on travaille des textes littéraires, notamment la poésie en vers.
</p>
      <%
      String text = request.getParameter( "text" );
      if ( text == null) text = "";
      %>
      <form method="post" action="?">
        <textarea name="text" style="width: 100%; height: 10em; "><%= text %></textarea>
        <!--
        <label>
          <input type="checkbox" name="stop"/>
        </label>
      -->
        <button type="submit">Envoyer</button>
      </form>
      <pre><%
      Tokenizer toks = new Tokenizer(text);
      int n = 1;
      Occ occ = new Occ();
      while ( toks.word( occ ) ) {
        out.print( occ );
        out.println();
      }
       %></pre>

     </article>
  </body>
 </html>
