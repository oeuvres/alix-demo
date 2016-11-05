<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
site.oeuvres.fr.Lexik,site.oeuvres.fr.Tag,site.oeuvres.fr.Tokenizer,site.oeuvres.fr.Occ" %>
<%
  request.setCharacterEncoding("UTF-8");
%>
<!DOCTYPE html>
<html>
  <head>
    <title>Le lemmatiseur du pauvre</title>
    <link rel="stylesheet" type="text/css" href="http://svn.code.sf.net/p/obvil/code/theme/obvil.css" />
    <style>
table.lem { font-family: sans-serif; border-collapse: collapse; border: 2px solid #FFFFFF; }
table.lem td { padding: 0 1ex; border-top: 1px solid #FFFFFF; }
    </style>
  </head>
  <body>
    <article id="article">
      <h1><a href=".">Alix</a> : un lemmatiseur qui tolère la poésie</h1>
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
        if ( text == null) text = "La Beauté "
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
      <form method="post" action="?">
        <textarea name="text" style="width: 100%; height: 10em; "><%=text%></textarea>
        <!--
        <label>
          <input type="checkbox" name="stop"/>
        </label>
      -->
        <button type="submit">Envoyer</button>
      </form>
      <table class="lem">
        <tr>
          <th>Graphie</th>
          <th>Forme</th>
          <th>Catégorie</th>
          <th>Lemme</th>
        </tr>
      <%
        Tokenizer toks = new Tokenizer(text);
        int n = 1;
        Occ occ = new Occ();
        while ( toks.word( occ ) ) {
          out.print("<tr><td>");
          out.print( occ.graph(  ) );
          out.print("</td><td>");
          out.print( occ.orth(  ) );
          out.print("</td><td>");
          out.print( Tag.label(occ.cat()) );
          out.print("</td><td>");
          out.print( occ.lem() );
          out.print("</td><tr>");
          out.println();
        }
      %>
       </table>

     </article>
  </body>
 </html>
