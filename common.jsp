<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%><%@ page import="

java.io.BufferedReader,
java.io.File,
java.io.InputStream,
java.io.InputStreamReader,
java.io.IOException,
java.io.PrintWriter,
java.nio.charset.StandardCharsets,
java.nio.file.Files,
java.nio.file.Path,
java.nio.file.Paths,
java.text.DecimalFormat,
java.text.DecimalFormatSymbols,
java.util.Arrays,
java.util.HashSet,
java.util.LinkedHashMap,
java.util.List,
java.util.Locale,
java.util.Set,
java.util.Scanner,

alix.fr.Lexik,
alix.fr.Lexik.LexEntry,
alix.fr.query.Query,
alix.fr.Tag,
alix.fr.Tokenizer,
alix.util.Char,
alix.util.DicBalance,
alix.util.DicBalance.Balance,
alix.util.DicPhrase,
alix.util.DicFreq,
alix.util.DicFreq.Entry,
alix.util.IntPair,
alix.util.IntRoller,
alix.util.IntSeries,
alix.util.Occ,
alix.util.OccRoller

" %><%!

static DecimalFormatSymbols frsyms = DecimalFormatSymbols.getInstance(Locale.FRANCE);
static DecimalFormat dfppm = new DecimalFormat("#,###", frsyms);
static DecimalFormat dfratio = new DecimalFormat("#,##0.0000", frsyms);

static HashSet<String> cloudfilter = new HashSet<String>();
static {
  for (String w: new String[]{
      "abbé", "baron", "celui", "chapitre", "cher", "comte", "comtesse", "do",
      "docteur", "duc", "duchesse", "évêque", "francs",
      "lord", "madame", "mademoiselle", 
      "maître", "marquis", "marquise", "miss", "monsieur", "p.", "pauvre", "point", "prince", "princesse", "professeur",
      "reine", "roi", "roy", "si", "sir", "ut"
  }) cloudfilter.add( w );
}
/** Writer */
private JspWriter printer;


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
    if ( l.length() < 1 ) continue;
    if ( l.charAt( 0 ) == '#' ) continue;
    cells = l.split(";");
    if ( cells.length < 1 ) continue;
    String[] value = new String[3];
    value[0] = cells[0];
    String key = cells[0];
    // folder, cut last /
    if ( key.endsWith( "/" ) ) key = key.substring( 0, key.length() - 1 );
    int pos = key.lastIndexOf( '/' );
    if ( pos > -1 ) key = key.substring( pos+1 );
    pos = key.lastIndexOf( '.' );
    if ( pos > -1 ) key = key.substring( 0, pos );
    if ( cells.length < 3 ) {
      pos = key.indexOf( '_' );
      if ( pos > 0 ) {
        value[1] = key.substring( 0, pos );
        value[2] = key.substring( pos+1 );
      }
      else {
        value[1] = key;
        value[2] = key;
      }
    }
    else {
      value[1] = cells[1];
      value[2] = cells[2];
    }
    catalog.put( key, value );
  }
  buf.close();
  pageContext.getServletContext().setAttribute( "catalog", catalog );
  return catalog;
}
static boolean bool( final PageContext pageContext, String param )
{
  String value = pageContext.getRequest().getParameter( param );
  if ( value == null || value.isEmpty() || "0".equals( value ) || "null".equals( value ) || "false".equals( value )) return false;
  return true;
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

  float[] values = { 200f, 100F, 50F, 20F, 10F, 7F, 6F, 5F, 3F, 2F, 0F, -2F, -5F, -10F };
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
  // directory
  if ( line[0].endsWith( "/" ) ) {
    Set<String> ls = pageContext.getServletContext().getResourcePaths( line[0] );
    if ( ls.size() < 1 ) return null;
    StringBuilder sb = new StringBuilder();
    for ( String path:ls ) {
      InputStream stream = pageContext.getServletContext().getResourceAsStream( path );
      if ( stream == null ) continue;
      Scanner sc = new Scanner( stream, "UTF-8" );
      // http://web.archive.org/web/20140531042945/https://weblogs.java.net/blog/pat/archive/2004/10/stupid_scanner_1.html
      sc.useDelimiter("\\A");
      String text = sc.next();
      sc.close();
      int pos = text.indexOf( "</teiHeader>" );
      if ( pos > 0 ) sb.append( text.substring( pos ) );
      else sb.append( text );
    }
    return sb.toString(  );
  }
  // file ?
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
public DicFreq parse( String text ) throws IOException {
  DicFreq dic = new DicFreq();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  short cat;
  while ( toks.word( occ ) ) {
    if ( occ.tag().isVerb() || occ.tag().code() == Tag.ADJ ) {
      dic.inc( occ.lem(), occ.tag().code() );
    }
    else dic.inc( occ.orth(), occ.tag().code() );
  }
  return dic;
}
public DicFreq dic( PageContext pageContext, final String bib ) throws IOException 
{
  return dic( pageContext, bib, "W");
}

/**
 * Récupérer un dictionnaire par identifiant, comportement général
 */
public DicFreq dic( PageContext pageContext, final String code, String type ) throws IOException 
{
  ServletContext application = pageContext.getServletContext();
  if ( type == null || type.isEmpty() ) type = "dic";
  String att = code + type;
  DicFreq dico = (DicFreq)application.getAttribute( att );
  if ( dico != null ) return dico;
  /*
  LinkedHashMap<String,String[]> catalog = catalog( pageContext );
  String[] bibl = catalog.get( bib );
  // texte inconnu
  if ( bibl == null ) return null;
  Scanner sc =  new Scanner( application.getResourceAsStream( bibl[0] ), "UTF-8" );
  */
  String text = text( pageContext, code );
  if ( text == null ) return null;
  DicFreq words = new DicFreq();
  DicFreq tags = new DicFreq();
  Tokenizer toks = new Tokenizer(text);
  Occ occ = new Occ();
  short cat;
  while ( toks.word( occ ) ) {
    if ( occ.tag().isVerb() || occ.tag().code() == Tag.ADJ ) {
      words.inc( occ.lem(), occ.tag().code() );
    }
    else words.inc( occ.orth(), occ.tag().code() );
    if ( occ.tag().isPun());
    else if( occ.tag().equals(Tag.UNKNOWN));
    else if( occ.tag().isName() ) tags.inc("NAME") ;
    else if( occ.tag().isDet() ) tags.inc("DET") ;
    else if( occ.tag().isDet() ) tags.inc("DET") ;
    else tags.inc( occ.tag().label(  ));
  }
  application.setAttribute( code+"W", words );
  application.setAttribute( code+"T", tags );
  if ( "W".equals( type )) return words;
  else if ( "T".equals( type )) return tags;
  else return null;
}

%><%

request.setCharacterEncoding("UTF-8");
// instantiate catalog
LinkedHashMap<String,String[]> catalog = catalog( pageContext );

%>