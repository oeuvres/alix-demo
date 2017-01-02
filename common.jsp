<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="
java.io.BufferedReader,
java.io.InputStream,
java.io.InputStreamReader,
java.io.IOException,
java.nio.charset.StandardCharsets,
java.nio.file.Files,
java.text.DecimalFormat,
java.text.DecimalFormatSymbols,
java.util.Scanner,
java.util.LinkedHashMap,
java.util.Locale,
java.util.Scanner,


alix.fr.Occ,
alix.fr.Tokenizer,
alix.fr.Lexik,
alix.fr.Tag,
alix.fr.WordEntry,
alix.util.TermDic

" %>
<%!static DecimalFormatSymbols frsyms = DecimalFormatSymbols.getInstance(Locale.FRANCE);
static DecimalFormat ppmdf = new DecimalFormat("#,###", frsyms);

/** Get catalog, populate it if empty */
static LinkedHashMap<String,String[]> catalog( PageContext pageContext ) throws IOException
{ 
  String force = pageContext.getRequest().getParameter( "force" );
  if ( force != null ) {
    pageContext.getServletContext().removeAttribute( "catalog" );
    pageContext.getRequest().removeAttribute( "force" ); // do not 2x
  }
  @SuppressWarnings("unchecked")
  LinkedHashMap<String,String[]> catalog = (LinkedHashMap<String,String[]>)pageContext.getServletContext().getAttribute( "catalog" );
  if ( catalog != null && force == null) return catalog;
  catalog = new LinkedHashMap<String,String[]>();
  BufferedReader buf = new BufferedReader( 
    new InputStreamReader(
      pageContext.getServletContext().getResourceAsStream( "/WEB-INF/catalog.csv" ), 
      StandardCharsets.UTF_8
    )
  );
  buf.readLine(); // skip first line
  String[] cells;
  String l;
  while ((l = buf.readLine()) != null) {
    if (l.charAt( 0 ) == '#' ) continue;
    cells = l.split(";");
    catalog.put( cells[0], new String[] { cells[1], cells[2], cells[3]} );
  }
  buf.close();
  pageContext.getServletContext().setAttribute( "catalog", catalog );
  return catalog;
}
/** Output a text selector for texts */
static void seltext( PageContext pageContext, String value ) throws IOException
{
  LinkedHashMap<String,String[]> catalog = catalog( pageContext );
  JspWriter out = pageContext.getOut();
  String selected = " selected=\"selected\" ";
  String sel = "";
  if (value == null) sel = selected;
  String[] cells = null;
  out.println("<option value=\"\" "+sel+">Choisir un texte…</option>");
  for ( String code: catalog.keySet(  ) ) {
    cells = catalog.get( code );
    if ( code.equals( value ) ) sel = selected;
    else sel = "";
    out.println("<option value=\""+code+"\""+sel+">"+cells[1]+". "+cells[2]+"</option>");
  }
}

/** 
 * Output options for Frantext filter
 */
static Float tlfoptions ( PageContext pageContext, String param ) throws IOException
{
   JspWriter out = pageContext.getOut();
  DecimalFormat frdf = new DecimalFormat("#.#", frsyms );
  Float tlfratio = null;
  if ( param != null ) {
    try { tlfratio = new Float( param ); }
    catch ( Exception e) {}
  }

  float[] values = { 200f, 100F, 50F, 20F, 10F, 7F, 5F, 3F, 2F, 0F, -2F, -5F, -10F };
  int lim = values.length;
  String selected="";
  boolean seldone = false;
  String label;
  for ( int i=0; i < lim; i++ ) {
    if ( !seldone && tlfratio != null && tlfratio >= values[i]) {
      selected=" selected=\"selected\"";
      seldone = true;
    }
    if ( values[i] == 0 ) label = "[2, -2]";
    else label = frdf.format( values[i] );
    out.println("<option"+selected+" value=\""+values[i]+"\">"+label +"</option>");
    selected = "";
  }
  return tlfratio;
}
/** Get text from a code */
static String text( PageContext pageContext, String code ) throws IOException
{
  LinkedHashMap<String,String[]> catalog = catalog( pageContext );
  String[] line = catalog.get( code );
  if ( line == null ) return null;
  InputStream stream = pageContext.getServletContext().getResourceAsStream( line[0] );
  if ( stream == null ) return null;
  Scanner sc = new Scanner( stream, "UTF-8" );
  sc.useDelimiter("\\A");
  String text = sc.next();
  sc.close();
  return text;
}

/**
 * Charger un dictionnaire avec les mots d’un texte, comportement général
 */
public TermDic parse( String text ) throws IOException {
  TermDic dic = new TermDic();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  short cat;
  while ( toks.word( occ ) ) {
    if ( occ.tag.VERB() || occ.tag.code() == Tag.ADJ ) {
      dic.inc( occ.lem, occ.tag.code() );
    }
    else dic.inc( occ.orth, occ.tag.code() );
  }
  return dic;
}
public TermDic dic( PageContext pageContext, final String bib ) throws IOException 
{
  return dic( pageContext, bib, "W");
}

/**
 * Récupérer un dictionnaire par identifiant, comportement général
 */
public TermDic dic( PageContext pageContext, final String bib, final String type ) throws IOException 
{
  ServletContext application = pageContext.getServletContext();
  String att = bib + type;
  TermDic dico = (TermDic)application.getAttribute( att );
  if ( dico != null ) return dico;
  LinkedHashMap<String,String[]> catalog = catalog( pageContext );
  String[] bibl = catalog.get( bib );
  // texte inconnu
  if ( bibl == null ) return null;
  /*
  String home = application.getRealPath("/");
  String filepath = home + "/textes/" + bibl[1];
  Path path =  Paths.get( filepath );
  new String( Files.readAllBytes( path ), StandardCharsets.UTF_8 )
  */
  // http://web.archive.org/web/20140531042945/https://weblogs.java.net/blog/pat/archive/2004/10/stupid_scanner_1.html
  Scanner sc =  new Scanner( application.getResourceAsStream( bibl[0] ), "UTF-8" );
  String text = sc.useDelimiter("\\A").next();
  sc.close();
  TermDic words = new TermDic();
  TermDic tags = new TermDic();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  short cat;
  while ( toks.word( occ ) ) {
    if ( occ.tag.VERB() || occ.tag.code() == Tag.ADJ ) {
      words.inc( occ.lem, occ.tag.code() );
    }
    else words.inc( occ.orth, occ.tag.code() );
    if ( occ.tag.PUN());
    else if( occ.tag.equals(Tag.UNKNOWN));
    else if( occ.tag.NAME() ) tags.inc("NAME") ;
    else if( occ.tag.DET() ) tags.inc("DET") ;
    else if( occ.tag.DET() ) tags.inc("DET") ;
    else tags.inc( occ.tag.label(  ));
  }
  application.setAttribute( bib+"W", words );
  application.setAttribute( bib+"T", tags );
  if ( "W".equals( type )) return words;
  else if ( "T".equals( type )) return tags;
  else return null;
}%>
<%
request.setCharacterEncoding("UTF-8");
// instantiate catalog
LinkedHashMap<String,String[]> catalog = catalog( pageContext );

%>