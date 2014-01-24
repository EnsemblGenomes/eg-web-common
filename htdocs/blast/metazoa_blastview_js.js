//----------------------------------------------------------------------
// Define global constants

var typeAry        = new Array( "dna","peptide" );
var methodAry      = new Array( "BLASTN","BLASTP","BLASTX","BLAT","TBLASTN","TBLASTX" );
var sensitivityValues = new Array();
var speciesAry     = new Array( "Aedes_aegypti","Anopheles_gambiae","Caenorhabditis_elegans","Culex_quinquefasciatus","Drosophila_melanogaster","Ixodes_scapularis" );
var databaseAry    = new Array( "LATESTGP","LATESTGP_MASKED","ATASOURCE_TYPE","CDNA_ALL","CDNA_KNOWN","CDNA_NOVEL","CDNA_PSEUDO","PEP_ALL","PEP_KNOWN","PEP_NOVEL","RNA_NC","CDNA_ABINITIO","PEP_ABINITIO" );

var methodConf        = new Array();
var sensitivityConf   = new Array();
var methodLabels      = new Array();
var sensitivityLabels = new Array();
var dbDnaLabels       = new Array();
var dbPeptideLabels   = new Array();

initMethodConf();
initSensitivityConf();
setAll();

var lastQueryType       = getQueryType();
var lastMethod          = getMethod();
var lastSensitivity     = getSensitivity();
var lastSpecies         = getSpecies();
var lastDatabaseType    = getDatabaseType();
var lastDatabaseDna     = getDatabaseDna();
var lastDatabasePeptide = getDatabasePeptide();
var defaultQueryType       = lastQueryType;
var defaultMethod          = lastMethod;
var defaultSensitivity     = lastSensitivity;
var defaultSpecies         = lastSpecies;
var defaultDatabaseType    = lastDatabaseType;
var defaultDatabaseDna     = lastDatabaseDna;
var defaultDatabasePeptide = lastDatabasePeptide;
//debug();

//----------------------------------------------------------------------
// Initialises the methodConf data
//
function initMethodConf(){
  
methodConf["dna"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["LATESTGP"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["LATESTGP"]["BLASTN"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["LATESTGP"]["TBLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_PSEUDO"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_PSEUDO"]["BLASTN"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_PSEUDO"]["TBLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["LATESTGP_MASKED"]["BLASTN"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["LATESTGP_MASKED"]["TBLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_ABINITIO"]["BLASTN"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_ABINITIO"]["TBLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_KNOWN"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_KNOWN"]["BLASTN"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_KNOWN"]["TBLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_ALL"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_ALL"]["BLASTN"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_ALL"]["TBLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_NOVEL"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_NOVEL"]["BLASTN"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["CDNA_NOVEL"]["TBLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["RNA_NC"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["RNA_NC"]["BLASTN"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["dna"]["RNA_NC"]["TBLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["peptide"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["peptide"]["PEP_ALL"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["peptide"]["PEP_ALL"]["BLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["peptide"]["PEP_ABINITIO"]["BLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["peptide"]["PEP_NOVEL"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["peptide"]["PEP_NOVEL"]["BLASTX"] = 1;
methodConf["dna"]["Culex_quinquefasciatus"]["peptide"]["PEP_KNOWN"] = new Array();
methodConf["dna"]["Culex_quinquefasciatus"]["peptide"]["PEP_KNOWN"]["BLASTX"] = 1;
methodConf["dna"]["Aedes_aegypti"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["dna"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["dna"]["LATESTGP"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["dna"]["LATESTGP"]["BLASTN"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["LATESTGP"]["TBLASTX"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["LATESTGP"]["BLAT"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["dna"]["LATESTGP_MASKED"]["BLASTN"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["LATESTGP_MASKED"]["TBLASTX"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["dna"]["CDNA_ABINITIO"]["BLASTN"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["CDNA_ABINITIO"]["TBLASTX"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["CDNA_ALL"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["dna"]["CDNA_ALL"]["BLASTN"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["CDNA_ALL"]["TBLASTX"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["RNA_NC"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["dna"]["RNA_NC"]["BLASTN"] = 1;
methodConf["dna"]["Aedes_aegypti"]["dna"]["RNA_NC"]["TBLASTX"] = 1;
methodConf["dna"]["Aedes_aegypti"]["peptide"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["peptide"]["PEP_ALL"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["peptide"]["PEP_ALL"]["BLASTX"] = 1;
methodConf["dna"]["Aedes_aegypti"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["dna"]["Aedes_aegypti"]["peptide"]["PEP_ABINITIO"]["BLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"]["LATESTGP"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"]["LATESTGP"]["BLASTN"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["LATESTGP"]["TBLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_PSEUDO"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_PSEUDO"]["BLASTN"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_PSEUDO"]["TBLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"]["LATESTGP_MASKED"]["BLASTN"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["LATESTGP_MASKED"]["TBLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_ABINITIO"]["BLASTN"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_ABINITIO"]["TBLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_KNOWN"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_KNOWN"]["BLASTN"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_KNOWN"]["TBLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_ALL"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_ALL"]["BLASTN"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_ALL"]["TBLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_NOVEL"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_NOVEL"]["BLASTN"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["CDNA_NOVEL"]["TBLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["RNA_NC"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["dna"]["RNA_NC"]["BLASTN"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["dna"]["RNA_NC"]["TBLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["peptide"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["peptide"]["PEP_ALL"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["peptide"]["PEP_ALL"]["BLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["peptide"]["PEP_ABINITIO"]["BLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["peptide"]["PEP_NOVEL"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["peptide"]["PEP_NOVEL"]["BLASTX"] = 1;
methodConf["dna"]["Ixodes_scapularis"]["peptide"]["PEP_KNOWN"] = new Array();
methodConf["dna"]["Ixodes_scapularis"]["peptide"]["PEP_KNOWN"]["BLASTX"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["dna"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["LATESTGP"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["LATESTGP"]["BLASTN"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["LATESTGP"]["TBLASTX"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["LATESTGP"]["BLAT"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["LATESTGP_MASKED"]["BLASTN"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["LATESTGP_MASKED"]["TBLASTX"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["CDNA_ABINITIO"]["BLASTN"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["CDNA_ABINITIO"]["TBLASTX"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["ATASOURCE_TYPE"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["ATASOURCE_TYPE"]["BLAT"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["CDNA_ALL"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["CDNA_ALL"]["BLASTN"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["CDNA_ALL"]["TBLASTX"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["RNA_NC"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["RNA_NC"]["BLASTN"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["dna"]["RNA_NC"]["TBLASTX"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["peptide"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["peptide"]["PEP_ALL"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["peptide"]["PEP_ALL"]["BLASTX"] = 1;
methodConf["dna"]["Caenorhabditis_elegans"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["dna"]["Caenorhabditis_elegans"]["peptide"]["PEP_ABINITIO"]["BLASTX"] = 1;
methodConf["dna"]["Drosophila_melanogaster"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["dna"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["LATESTGP"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["LATESTGP"]["BLASTN"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["LATESTGP"]["TBLASTX"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["LATESTGP"]["BLAT"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["LATESTGP_MASKED"]["BLASTN"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["LATESTGP_MASKED"]["TBLASTX"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["CDNA_ABINITIO"]["BLASTN"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["CDNA_ABINITIO"]["TBLASTX"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["CDNA_ALL"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["CDNA_ALL"]["BLASTN"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["CDNA_ALL"]["TBLASTX"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["RNA_NC"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["RNA_NC"]["BLASTN"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["dna"]["RNA_NC"]["TBLASTX"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["peptide"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["peptide"]["PEP_ALL"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["peptide"]["PEP_ALL"]["BLASTX"] = 1;
methodConf["dna"]["Drosophila_melanogaster"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["dna"]["Drosophila_melanogaster"]["peptide"]["PEP_ABINITIO"]["BLASTX"] = 1;
methodConf["dna"]["Anopheles_gambiae"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["dna"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["dna"]["LATESTGP"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["dna"]["LATESTGP"]["BLASTN"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["dna"]["LATESTGP"]["TBLASTX"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["dna"]["LATESTGP_MASKED"]["BLASTN"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["dna"]["LATESTGP_MASKED"]["TBLASTX"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["dna"]["CDNA_ABINITIO"]["BLASTN"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["dna"]["CDNA_ABINITIO"]["TBLASTX"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["dna"]["CDNA_ALL"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["dna"]["CDNA_ALL"]["BLASTN"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["dna"]["CDNA_ALL"]["TBLASTX"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["dna"]["RNA_NC"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["dna"]["RNA_NC"]["BLASTN"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["dna"]["RNA_NC"]["TBLASTX"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["peptide"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["peptide"]["PEP_ALL"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["peptide"]["PEP_ALL"]["BLASTX"] = 1;
methodConf["dna"]["Anopheles_gambiae"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["dna"]["Anopheles_gambiae"]["peptide"]["PEP_ABINITIO"]["BLASTX"] = 1;
methodConf["peptide"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["LATESTGP"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["LATESTGP"]["TBLASTN"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_PSEUDO"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_PSEUDO"]["TBLASTN"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["LATESTGP_MASKED"]["TBLASTN"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_ABINITIO"]["TBLASTN"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_KNOWN"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_KNOWN"]["TBLASTN"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_ALL"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_ALL"]["TBLASTN"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_NOVEL"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["CDNA_NOVEL"]["TBLASTN"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["RNA_NC"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["dna"]["RNA_NC"]["TBLASTN"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["peptide"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["peptide"]["PEP_ALL"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["peptide"]["PEP_ALL"]["BLASTP"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["peptide"]["PEP_ABINITIO"]["BLASTP"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["peptide"]["PEP_NOVEL"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["peptide"]["PEP_NOVEL"]["BLASTP"] = 1;
methodConf["peptide"]["Culex_quinquefasciatus"]["peptide"]["PEP_KNOWN"] = new Array();
methodConf["peptide"]["Culex_quinquefasciatus"]["peptide"]["PEP_KNOWN"]["BLASTP"] = 1;
methodConf["peptide"]["Aedes_aegypti"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["dna"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["dna"]["LATESTGP"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["dna"]["LATESTGP"]["TBLASTN"] = 1;
methodConf["peptide"]["Aedes_aegypti"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["dna"]["LATESTGP_MASKED"]["TBLASTN"] = 1;
methodConf["peptide"]["Aedes_aegypti"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["dna"]["CDNA_ABINITIO"]["TBLASTN"] = 1;
methodConf["peptide"]["Aedes_aegypti"]["dna"]["CDNA_ALL"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["dna"]["CDNA_ALL"]["TBLASTN"] = 1;
methodConf["peptide"]["Aedes_aegypti"]["dna"]["RNA_NC"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["dna"]["RNA_NC"]["TBLASTN"] = 1;
methodConf["peptide"]["Aedes_aegypti"]["peptide"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["peptide"]["PEP_ALL"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["peptide"]["PEP_ALL"]["BLASTP"] = 1;
methodConf["peptide"]["Aedes_aegypti"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["peptide"]["Aedes_aegypti"]["peptide"]["PEP_ABINITIO"]["BLASTP"] = 1;
methodConf["peptide"]["Ixodes_scapularis"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["LATESTGP"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["LATESTGP"]["TBLASTN"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_PSEUDO"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_PSEUDO"]["TBLASTN"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["LATESTGP_MASKED"]["TBLASTN"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_ABINITIO"]["TBLASTN"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_KNOWN"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_KNOWN"]["TBLASTN"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_ALL"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_ALL"]["TBLASTN"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_NOVEL"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["CDNA_NOVEL"]["TBLASTN"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["RNA_NC"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["dna"]["RNA_NC"]["TBLASTN"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["peptide"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["peptide"]["PEP_ALL"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["peptide"]["PEP_ALL"]["BLASTP"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["peptide"]["PEP_ABINITIO"]["BLASTP"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["peptide"]["PEP_NOVEL"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["peptide"]["PEP_NOVEL"]["BLASTP"] = 1;
methodConf["peptide"]["Ixodes_scapularis"]["peptide"]["PEP_KNOWN"] = new Array();
methodConf["peptide"]["Ixodes_scapularis"]["peptide"]["PEP_KNOWN"]["BLASTP"] = 1;
methodConf["peptide"]["Caenorhabditis_elegans"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["LATESTGP"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["LATESTGP"]["TBLASTN"] = 1;
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["LATESTGP_MASKED"]["TBLASTN"] = 1;
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["CDNA_ABINITIO"]["TBLASTN"] = 1;
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["CDNA_ALL"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["CDNA_ALL"]["TBLASTN"] = 1;
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["RNA_NC"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["dna"]["RNA_NC"]["TBLASTN"] = 1;
methodConf["peptide"]["Caenorhabditis_elegans"]["peptide"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["peptide"]["PEP_ALL"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["peptide"]["PEP_ALL"]["BLASTP"] = 1;
methodConf["peptide"]["Caenorhabditis_elegans"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["peptide"]["Caenorhabditis_elegans"]["peptide"]["PEP_ABINITIO"]["BLASTP"] = 1;
methodConf["peptide"]["Drosophila_melanogaster"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["dna"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["LATESTGP"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["LATESTGP"]["TBLASTN"] = 1;
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["LATESTGP_MASKED"]["TBLASTN"] = 1;
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["CDNA_ABINITIO"]["TBLASTN"] = 1;
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["CDNA_ALL"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["CDNA_ALL"]["TBLASTN"] = 1;
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["RNA_NC"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["dna"]["RNA_NC"]["TBLASTN"] = 1;
methodConf["peptide"]["Drosophila_melanogaster"]["peptide"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["peptide"]["PEP_ALL"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["peptide"]["PEP_ALL"]["BLASTP"] = 1;
methodConf["peptide"]["Drosophila_melanogaster"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["peptide"]["Drosophila_melanogaster"]["peptide"]["PEP_ABINITIO"]["BLASTP"] = 1;
methodConf["peptide"]["Anopheles_gambiae"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["dna"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["LATESTGP"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["LATESTGP"]["TBLASTN"] = 1;
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["LATESTGP_MASKED"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["LATESTGP_MASKED"]["TBLASTN"] = 1;
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["CDNA_ABINITIO"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["CDNA_ABINITIO"]["TBLASTN"] = 1;
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["CDNA_ALL"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["CDNA_ALL"]["TBLASTN"] = 1;
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["RNA_NC"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["dna"]["RNA_NC"]["TBLASTN"] = 1;
methodConf["peptide"]["Anopheles_gambiae"]["peptide"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["peptide"]["PEP_ALL"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["peptide"]["PEP_ALL"]["BLASTP"] = 1;
methodConf["peptide"]["Anopheles_gambiae"]["peptide"]["PEP_ABINITIO"] = new Array();
methodConf["peptide"]["Anopheles_gambiae"]["peptide"]["PEP_ABINITIO"]["BLASTP"] = 1;
  var dbDnaSelect = document.settings.database_dna;
  if( dbDnaSelect ){
    for( var i=0; i<dbDnaSelect.length; i++ ){
      dbDnaLabels[dbDnaSelect[i].value]=dbDnaSelect[i].text;
    }
  }

  // method labels
  var meSelect = document.settings.method;
  if( meSelect ){
    for( var i=0; i<meSelect.length; i++ ){
      methodLabels[meSelect[i].value]=meSelect[i].text;
    }
  }

  // db Labels
  var dbPeptideSelect = document.settings.database_peptide;
  if( dbPeptideSelect ){
    for( var i=0; i<dbPeptideSelect.length; i++ ){
      dbPeptideLabels[dbPeptideSelect[i].value]=dbPeptideSelect[i].text;
    }
  }
}

//----------------------------------------------------------------------
// Initialises the sensitivityConf data
//
function initSensitivityConf(){
  
sensitivityConf["BLASTN"] = new Array();
sensitivityConf["BLASTN"]["LOW"] = 1;
sensitivityConf["BLASTN"]["MEDIUM"] = 1;
sensitivityConf["BLASTN"]["HIGH"] = 1;
sensitivityConf["BLASTN"]["EXACT"] = 1;
sensitivityConf["BLASTN"]["OLIGO"] = 1;
sensitivityConf["BLASTN"]["DEFAULT"] = 1;
sensitivityConf["BLASTN"]["CUSTOM"] = 1;
sensitivityConf["BLASTP"] = new Array();
sensitivityConf["BLASTP"]["LOW"] = 1;
sensitivityConf["BLASTP"]["MEDIUM"] = 1;
sensitivityConf["BLASTP"]["HIGH"] = 1;
sensitivityConf["BLASTP"]["EXACT"] = 1;
sensitivityConf["BLASTP"]["SHORT"] = 1;
sensitivityConf["BLASTP"]["DEFAULT"] = 1;
sensitivityConf["BLASTP"]["CUSTOM"] = 1;
sensitivityConf["BLASTX"] = new Array();
sensitivityConf["BLASTX"]["LOW"] = 1;
sensitivityConf["BLASTX"]["MEDIUM"] = 1;
sensitivityConf["BLASTX"]["HIGH"] = 1;
sensitivityConf["BLASTX"]["EXACT"] = 1;
sensitivityConf["BLASTX"]["DEFAULT"] = 1;
sensitivityConf["BLASTX"]["CUSTOM"] = 1;
sensitivityConf["BLAT"] = new Array();
sensitivityConf["BLAT"]["LOW"] = 1;
sensitivityConf["BLAT"]["MEDIUM"] = 1;
sensitivityConf["BLAT"]["HIGH"] = 1;
sensitivityConf["BLAT"]["EXACT"] = 1;
sensitivityConf["BLAT"]["DEFAULT"] = 1;
sensitivityConf["BLAT"]["CUSTOM"] = 1;
sensitivityConf["TBLASTN"] = new Array();
sensitivityConf["TBLASTN"]["LOW"] = 1;
sensitivityConf["TBLASTN"]["MEDIUM"] = 1;
sensitivityConf["TBLASTN"]["HIGH"] = 1;
sensitivityConf["TBLASTN"]["EXACT"] = 1;
sensitivityConf["TBLASTN"]["SHORT"] = 1;
sensitivityConf["TBLASTN"]["DEFAULT"] = 1;
sensitivityConf["TBLASTN"]["CUSTOM"] = 1;
sensitivityConf["TBLASTX"] = new Array();
sensitivityConf["TBLASTX"]["LOW"] = 1;
sensitivityConf["TBLASTX"]["MEDIUM"] = 1;
sensitivityConf["TBLASTX"]["HIGH"] = 1;
sensitivityConf["TBLASTX"]["EXACT"] = 1;
sensitivityConf["TBLASTX"]["DEFAULT"] = 1;
sensitivityConf["TBLASTX"]["CUSTOM"] = 1;
  var sensSelect = document.settings.sensitivity;
  if( sensSelect ){
    for( var i=0; i<sensSelect.length; i++ ){
      sensitivityValues.push(sensSelect[i].value);
      sensitivityLabels[sensSelect[i].value]=sensSelect[i].text;
    }
  }
}


//----------------------------------------------------------------------
// Determines whether there is any values in the methodConf array for
// the given queryType, method, species, and returs it
//
function getConf( queryType, species, databaseType, database, method ){

  var level1 = queryType;
  var level2 = species;
  var level3 = databaseType;
  var level4 = database;
  var level5 = method;

  // Does methodConf contain data? continue?
  if( methodConf ){

    // Do we have a level1 value? if not, just return the methodConf
    if( ! level1 ){ return methodConf; }

    // Does the level1 value have conf data? 
    if( methodConf[level1] ){
      
      // Do we have a level2 value if not, just return the level1 conf
      var level1Ary = methodConf[level1];
      if( ! level2 ){ return level1Ary; }

      // Does the level2 value have conf data? 
      if( level1Ary[level2] ){
 
        // Do we have a level 3 value? if not, just return the level2 conf
        var level2Ary = level1Ary[level2];
        if( ! level3 ){ return level2Ary; }

        // Does the level3 value have conf data?
        if( level2Ary[level3] ){
          
          // Do we have a level4 value? if not, just return the level3 conf
          var level3Ary = level2Ary[level3];
          if( ! level4 ){ return level3Ary }

          //Does the level4 value have conf data?
          if( level3Ary[level4] ){

            // Do we have a level5 value? if not, just return the level4 conf
            var level4Ary = level3Ary[level4];
            if( ! level5 ){ return level4Ary }

            // Done!
            return level4Ary[level5];
          }
        } 
      }
    }
  }
  // Failed - no conf data to return
  return false;
}

//----------------------------------------------------------------------
// Sets all form elements
//
function setAll(){
  setQueryType();
  setSpecies();
  setDatabaseType();
  setDatabase();
  setMethod();
  setSensitivity();
  return;
}

//----------------------------------------------------------------------
// Runs the required routines when qeryType has changed
//
function changedQueryType(){
  setSpecies();
  setDatabaseType();
  setDatabase();
  setMethod();
  setSensitivity();
  return;
}

//----------------------------------------------------------------------
// Runs the required routines when species has changed
//
function changedSpecies(){
  setDatabaseType();
  setDatabase();
  setMethod();
  setSensitivity();
  return;
}

//----------------------------------------------------------------------
// Runs the required routines when database has changed
//
function changedDatabaseType(){
  setMethod();
  setSensitivity();
  return;
}

//----------------------------------------------------------------------
// Runs the required routines when database_dna has changed
//
function changedDatabaseDna(){
  var dt = getDatabaseType();
  if( dt != 'dna' ){ return }
  setMethod();
  setSensitivity();
  return;
}

//----------------------------------------------------------------------
// Runs the required routines when database_peptide has changed
//
function changedDatabasePeptide(){
  var dt = getDatabaseType();
  if( dt != 'peptide' ){ return }
  setMethod();
  setSensitivity();
  return;
}



//----------------------------------------------------------------------
// Runs the required routines when qeryType has changed
//
function changedMethod(){
  setSensitivity();
  return;
}


//----------------------------------------------------------------------
// Sets the query type depending on query sequence
//
function changedQuerySequence( ){
  //alert( "setQueryType" );
  var sequence = document.settings._query_sequence.value;
  var letters = 0;
  var count = 0;
  var residue = "";
  var percentage;
  var sequence_to_check;
  var spaces = 0;
  var bases = "ACGTNX";
  var base_found;
  var space_or_digits = '01234 56789';
  var space_or_digit_found;
  var dna_threshold = 85;

// **********************************************************************
// count                holds the cumulative number of "ACGTNX"
// residue              single residue in the sequence 
// percentage           the % of the sequence that is "ACGTNX"
// def_line_end         position of the end of the definition line
// sequence_to_check    sequence without the definition line
// spaces               number of spaces or digits found
// bases                valid list of bases
// base_found           was a valid base found?
// space_or_digits      invalid chars 
// space_or_digit_found was an invalid char found?
// **********************************************************************

  var seqLength = 1000;
  if( sequence.length < seqLength ){ seqLength = sequence.length }

  for( var i=0; i<seqLength; i++ ){
    var residue = sequence.charAt(i).toUpperCase();
    // Check to see if FASTA header
    // If so, skip to next newline
    if( residue == '>' ){
      for( i=i++; i<seqLength; i++ ){
        residue = sequence.charAt(i);
        if( residue == '\n' ){ break }
      }
    }

    // Find all the 123456789 chars 
    space_or_digit_found = space_or_digits.indexOf( residue )
    if( space_or_digit_found >= 0 ){ continue }
    if( residue == '\n' ){ continue }
    if( residue == '\t' ){ continue }

    // Find all the ACGTNX chars - valid bases
    // If it is not found the return value is -1
    base_found = bases.indexOf( residue );
    if ( base_found >= 0 ){ count++; }

    letters++;
  }

  percentage = ( count / letters ) * 100;

  var newQueryType = "dna";
  if( percentage < dna_threshold ){
    newQueryType = "peptide";
  }

  // Update the queryType radio group
  for( var i=0; i<document.settings.query.length; i++ ){
    document.settings.query[i].checked = false;
    if( document.settings.query[i].value == newQueryType ){
      document.settings.query[i].checked = true;
    }
  }
  changedQueryType();
}

//----------------------------------------------------------------------
// Returns the currently seleted seq type
//
function getQueryType(){
  if( ! document.settings.query ){ 
    alert( "The query form element was not found" );
    return;
  }
  var val = radioValue( document.settings.query );
  if( val ){ return val }
  return 'dna';
}

//----------------------------------------------------------------------
// Returns the currently seleted method
//
function getMethod(){
  if( ! document.settings.method ){ 
    alert( "The method form element was not found" );
    return;
  }
  return( selectValue( document.settings.method ) );
}

//----------------------------------------------------------------------
// Returns the currently seleted sensitivity
//
function getSensitivity(){
  if( ! document.settings.sensitivity ){ 
    alert( "The sensitivity form element was not found" );
    return;
  }
  return( selectValue( document.settings.sensitivity ) );
}

//----------------------------------------------------------------------
// Returns an array of the currently seleted species
//
function getSpecies(){
  // Make sure focus form exists
  if( ! document.settings.species ){ 
    alert( "The species form element was not found" );
    return;
  }
  return( selectValues( document.settings.species ) );
  //return( checkboxValues( document.settings.species ) );
}

//----------------------------------------------------------------------
// Returns the currently selected database type
//
function getDatabaseType(){
  if( ! document.settings.database ){ 
    alert( "The database_type element was not found" );
    return;
  }
  return( radioValue( document.settings.database ) );
}

//----------------------------------------------------------------------
// Returns the currently selected dna database
//
function getDatabaseDna(){
  var element = document.settings.database_dna;
  if( ! element ){ 
    alert( "The 'database_dna' form element was not found" );
    return;
  }
  return( selectValue( element ) );
}

//----------------------------------------------------------------------
// Returns the currently selected dna database
//
function getDatabasePeptide(){
  var element = document.settings.database_peptide;
  if( ! element ){ 
    alert( "The 'database_peptide' form element was not found" );
    return;
  }
  return( selectValue( element ) );
}

//----------------------------------------------------------------------
// Sets the queryType based on methodConf
//
function setQueryType(){
  var radio = document.settings.query;
  if( ! radio ){
    alert( "The 'query' form element was not found" );
    return;
  }
  for( var i=0; i<typeAry.length; i++ ){
    var queryType = typeAry[i];
    if( typeof getConf( queryType ) == 'object' ) {
      enableRadio( radio,  queryType );
    } else {
      disableRadio( radio,  queryType );
    }
  }
}

//----------------------------------------------------------------------
// Sets the method depending on query
function setMethod(){
  var qt    = getQueryType();
  var spAry = getSpecies();
  var dt    = getDatabaseType();
  var db;

  if( dt == "dna" )    { db = getDatabaseDna() }
  if( dt == "peptide" ){ db = getDatabasePeptide() }

  if( getMethod() != 0 ){ lastMethod = getMethod() }
  if( defaultMethod == undefined ){ defaultMethod = lastMethod }

  var selectGrp  = document.settings.method;
  var meValues = new Array();
  for( var j=0; j<spAry.length; j++ ){
    var sp = spAry[j];
    var meAry = new Array();
    for( var i=0; i<methodAry.length; i++ ){
      var me = methodAry[i];
      if( getConf( qt, sp, dt, db, me ) == 1 ) { meAry.push( me ); }
    }
    meValues.push( meAry );
  }
  meValues = arrayUnion( meValues );

  setSelectOptions( selectGrp, meValues, methodLabels, defaultMethod );
}

//----------------------------------------------------------------------
// Sets the sensitivity options depending on method
function setSensitivity(){
  var me = getMethod();

  if( getSensitivity() != 0 ){ lastSensitivity = getSensitivity() }
  if( defaultSensitivity == undefined ){ defaultSensitivity = lastSensitivity }

  var sensSelectGrp = document.settings.sensitivity;
  var sensValues = new Array();
  for( var i=0; i<sensitivityValues.length; i++ ){
    var sens = sensitivityValues[i];
    if( sensitivityConf[me][sens] ) { sensValues.push( sens ); }
  }
  setSelectOptions( sensSelectGrp, sensValues, sensitivityLabels, defaultSensitivity );
}

//----------------------------------------------------------------------
// Sets the species depending on query
//
function setSpecies(){

  var queryType  = getQueryType();
  var defSpecies = getSpecies(); 
  var control    = document.settings.species;
}

//----------------------------------------------------------------------
// Sets the database type depending on other opts and methodConf
//
function setDatabaseType(){
  var queryType    = getQueryType();
  var databaseType = getDatabaseType();
  var species      = getSpecies();

  if( databaseType == undefined ){ databaseType = lastDatabaseType }
  lastDatabaseType = databaseType;

  var radio     = document.settings.database;
  //var method    = getMethod();

  var enableAry  = new Array();
  var disableAry = new Array();

  for( var j=0; j<typeAry.length; j++ ){
    var dt = typeAry[j];
    var enabled = 1;

    if( ! species.length ) { disableAry.push( dt ); }
    else{
      for( var i=0; i<species.length; i++ ){
        var sp = species[i];
        if( typeof getConf( queryType, sp, dt ) != 'object' ) {
          disableAry.push( dt );
        } else {
          enableAry.push( dt );
        }
      }
    }
  }
  for( var i=0; i<enableAry.length; i++ ) {
    var isChecked = false;
    if( enableAry[i] == lastDatabaseType ) { isChecked = true }
    enableRadio( radio, enableAry[i], isChecked );
  }
  for( var i=0; i<disableAry.length; i++ ) { disableRadio( radio, disableAry[i] ); } 
}

//----------------------------------------------------------------------
// Sets the target DB options depending on other options
//
function setDatabase(){
  var nuclTargetDB = document.settings.database_dna;
  var protTargetDB = document.settings.database_peptide;

  // Create an array of selected species
  var selSpecies = getSpecies();
  var selQType   = getQueryType();

  var databaseDna     = getDatabaseDna();
  var databasePeptide = getDatabasePeptide();
  if( databaseDna     != 0 ){ lastDatabaseDna     = databaseDna     }
  if( databasePeptide != 0 ){ lastDatabasePeptide = databasePeptide }

  var optNuclValues = new Array();
  var optProtValues = new Array();
  for( var i=0; i<selSpecies.length; i++ ){
    var sp = selSpecies[i];

    var nAry = new Array();
    var pAry = new Array();

    for( var j=0; j<databaseAry.length; j++ ){
      var db = databaseAry[j];
      if( typeof getConf( selQType, sp, 'dna', db ) == 'object' ) { nAry.push( db ); }
      if( typeof getConf( selQType, sp, 'peptide', db ) == 'object' ) { pAry.push( db ); }
    }
    optNuclValues.push( nAry );  
    optProtValues.push( pAry );
  }
  var optNuclValues = arrayUnion( optNuclValues );
  var optProtValues = arrayUnion( optProtValues );
  var optNuclLabels = new Array();
  var optProtLabels = new Array();

  setSelectOptions( nuclTargetDB, optNuclValues, dbDnaLabels, lastDatabaseDna );
  setSelectOptions( protTargetDB, optProtValues, dbPeptideLabels, lastDatabasePeptide );

}
