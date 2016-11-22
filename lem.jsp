<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.net.URL,
java.util.Scanner,

alix.fr.Lexik,
alix.fr.Tag,
alix.fr.Tokenizer,
alix.fr.Occ
" %>
<% request.setCharacterEncoding("UTF-8"); %>
<!DOCTYPE html>
<html>
  <head>
    <title>Le lemmatiseur du pauvre</title>
    <link rel="stylesheet" type="text/css" href="alix.css" />
    <style>
    </style>
  </head>
  <body>
    <article>
      <h1><a href=".">Alix</a> : <a href="">un lemmatiseur qui tolère la poésie</a></h1>
      <p>
Les vers passent en général très mal dans un lemmatiseur, car les majuscules ne coïncident pas avec
la ponctuation, si bien qu’ils produisent beaucoup de faux noms propres, et autres erreurs imprévisibles.
En réaction, ce lemmatiseur adopte des stratégies plus simples, mais plus soignées sur les dictionnaires et le découpage des mots.
Pour une forme graphique, le principe initial est de donner le lemme le plus fréquent.
Obligatoirement, l’étiquetage sera fautif sur les homographes les moins fréquents,
ainsi “est” est toujours considérée comme l’auxilliaire “être”.
Mais comme ce sont justement des mots moins fréquents, 
cela produit moins d’erreurs que des stratégies plus savantes avec des algorithmes.
L’autre avantage, c’est que ces erreurs sont déterministes, elles dépendent de dictionnaire maîtrisés,
et non pas d’un entraînement sur des corpus de textes non précisés.
Il en résulte que la sortie est plus fiable pour y appuyer des jeux de règles, ou des entraînements
statistiques, pouvant corriger les erreurs restantes si elles nuisaient à une applications particulière.
</p>
      <%
      String text = request.getParameter( "text" );
      %>
      <form method="post" action="?">
        <label>
          <% boolean unknown = !(request.getParameter( "unknown" ) == null);  %>
          <input type="checkbox" name="unknown" <% if(unknown) out.print( " checked=\"checked\"" ); %> />
          (Unknown) voir uniquement les erreurs
        </label>
        <% String url = request.getParameter( "url" ); if (url == null) url=""; %>
        <label>
          <input name="url" value="<%= url %>" size="50" onclick="this.select()" placeholder="http://…" 
          onchange="if (!value) return; this.form.method = 'GET'; this.form.text.value = ''"/>
          texte sur le web
        </label>
        <%
      if ( !"".equals( url ) ) {
        try {
          Scanner scan = new Scanner(  new URL( url ).openStream(), "UTF-8" );
          scan.useDelimiter("\\A"); 
          text = scan.next();
          scan.close();
        }
        catch (Exception e) {
          out.print( "<p>"+url+" Impossible de retirer le texte souhaité.</p>" );
          text = null;
        }
      }
      if ( text == null) text = "La Beauté\n\n"
      + "Je suis belle, ô mortels! comme un rêve de pierre,\n"
      + "Et mon sein, où chacun s'est meurtri tour à tour,\n"
      + "Est fait pour inspirer au poète un amour\n"
      + "Éternel et muet ainsi que la matière.\n"
      + "\n"
      + "Je trône dans l'azur comme un sphinx incompris;\n"
      + "J'unis un cœur de neige à la blancheur des cygnes;\n"
      + "Je hais le mouvement qui déplace les lignes,\n"
      + "Et jamais je ne pleure et jamais je ne ris.\n"
      + "\n"
      + "Les poètes, devant mes grandes attitudes,\n"
      + "Que j'ai l'air d'emprunter aux plus fiers monuments,\n"
      + "Consumeront leurs jours en d'austères études;\n"
      + "\n"
      + "Car j'ai, pour fasciner ces dociles amants,\n"
      + "De purs miroirs qui font toutes choses plus belles:\n"
      + "Mes yeux, mes larges yeux aux clartés éternelles!\n";
      %>
        <textarea name="text" style="width: 100%; height: 10em; " onchange="this.form.method='post'; " onclick="this.select()"><%=text%></textarea>
        <button type="submit">Envoyer</button>
      </form>
      <table class="lem">
        <tr>
          <th>Graphie</th>
          <th>Forme</th>
          <th>Catégorie</th>
          <th>Lemme</th>
          <th>Index</th>
        </tr>
      <%
        Tokenizer toks = new Tokenizer(text);
        int n = 1;
        Occ occ = new Occ();
        while ( toks.word( occ ) ) {
          if ( unknown && !occ.tag.equals( Tag.UNKNOWN )) continue;
          out.print("<tr><td>");
          out.print( occ.graph );
          out.print("</td><td>");
          out.print( occ.orth );
          out.print("</td><td>");
          out.print( occ.tag.label() );
          out.print("</td><td>");
          out.print( occ.lem );
          out.print("</td><td>");
          out.print( occ.start );
          out.print( '–' );
          out.print( occ.end );
          out.print("</td><tr>");
          out.println();
        }
      %>
       </table>

     </article>
  </body>
 </html>
