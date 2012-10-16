# TODO: use namespaces
# TODO: remake a complete hash-like description of UNIMARC fields, parsing the docs
# README: [Cristiano] Se mai rimetteremo mano al codice che ora comunque soddisfa le
# esigenze del progetto pilota, direi di dare un'occhiata a
# https://github.com/ruby-marc/ruby-marc
# anche se marc e unimarc sono due cose un po' diverse

module UnimarcConfig

  class ParsingException < Exception
    attr_reader :message
    def initialize(message)
      @message = "Unimarc::ParsingException error: UNIMARC format not recognized. #{message}"
    end
  end

  def self.included(klass)
    klass.extend Unimarc::ClassMethods
  end

  module ClassMethods
    def search(constant, search_string)
      selected_items = constant.select do |code, description|
        description =~ Regexp.new(search_string, true) # not nil parameter in second position returns a case insensitive regexp
      end

      ::Hash[*selected_items.flatten]
    end

    def search_fields(search_string)
      search(Unimarc::FIELDS, search_string)
    end

    def search_blocks(search_string)
      search(Unimarc::BLOCKS, search_string)
    end

    def description_for_unimarc_link(unimarc_field, lang)
      if Unimarc::UNIMARC_LINK_FIELDS[unimarc_field].present?
        Unimarc::UNIMARC_LINK_FIELDS[unimarc_field][:description][lang.to_sym]
      end
    end

  end # ClassMethods

  BLOCKS = {
    "0" => "Identification Block",
    "1" => "Coded Information Block",
    "2" => "Descriptive Information Block",
    "3" => "Notes Block",
    "4" => "Linking Entry Block",
    "5" => "Related Title Block",
    "6" => "Subject Analysis Block",
    "7" => "Intellectual Responsibility Block",
    "8" => "International Use Block",
    "9" => "National Use Block"
  }

  FIELDS = {
    "001" => "Record Identifier",
    "005" => "Version Identifier",
    "010" => "International Standard Book Number (ISBN)",
    "011" => "International Standard Serial Number (ISSN)",
    "012" => "Fingerprint identifier",
    "013" => "International Standard Music Number (ISMN)",
    "014" => "Article identifier",
    "015" => "International Standard Report Number (ISRN)",
    "016" => "International Standard Recording Code (ISRC)",
    "017" => "[Reserved for other International Standard Numbers]",
    "018" => "[Reserved for other International Standard Numbers]",
    "020" => "National Bibliography Number",
    "021" => "Legal Deposit Number",
    "022" => "Government Publication Number",
    "035" => "Other Systems Control Numbers",
    "040" => "CODEN",
    "071" => "Publishers' Numbers for Music",
    "100" => "General Processing Data",
    "101" => "Language of the Item",
    "102" => "Country of Publication or Production",
    "105" => "Coded Data Field: Textual Material, Monographic",
    "106" => "Coded Data Field: Textual Materials - Physical Attributes",
    "110" => "Coded Data Field: Serials",
    "115" => "Coded Data Field: Visual Projections, Video Recordings and Motion Pictures",
    "116" => "Coded Data Field: Graphics",
    "117" => "Coded Data Field: Three-dimensional Artefacts and Realia",
    "120" => "Coded Data Field: Cartographic Materials - General",
    "121" => "Coded Data Field: Cartographic Materials - Physical Attributes",
    "122" => "Coded Data Field: Time Period of Item Content",
    "123" => "Coded Data Field: Cartographic Materials - Scale and Co-ordinates",
    "124" => "Coded Data Field: Cartographic Materials - Specific Material Designation",
    "125" => "Coded Data Field: Sound Recordings and Printed Music",
    "126" => "Coded Data Field: Sound Recordings - Physical Attributes",
    "127" => "Coded Data Field: Duration of Sound Recordings and Printed Music",
    "128" => "Coded Data Field: Music Performances and Scores",
    "130" => "Coded Data Field: Microforms",
    "131" => "Coded Data Field: Cartographic Materials - Geodetic, Grid and Vertical Measurement",
    "135" => "Coded Data Field: Electronic Resources",
    "140" => "Coded Data Field: Antiquarian - General",
    "141" => "Coded Data Field: Antiquarian - Copy Specific Attributes",
    "200" => "Title and Statement of Responsibility",
    "204" => "[General Material Designation * Obsolete *]",
    "205" => "Edition Statement",
    "206" => "Material Specific Area: Cartographic Materials - Mathematical Data",
    "207" => "Material Specific Area: Serials - Numbering",
    "208" => "Material Specific Area: Printed Music",
    "210" => "Publication, Distribution, etc.",
    "211" => "Projected Publication Date",
    "215" => "Physical Description",
    "225" => "Series",
    "230" => "Material Specific Area: Electronic Resource Characteristics",
    "300" => "General Note",
    "301" => "Notes Pertaining to Identification Numbers",
    "302" => "Notes Pertaining to Coded Information",
    "303" => "General Notes Pertaining to Descriptive Information",
    "304" => "Notes Pertaining to Title and Statement of Responsibility",
    "305" => "Notes Pertaining to Edition and Bibliographic History",
    "306" => "Notes Pertaining to Publication, Distribution, etc.",
    "307" => "Notes Pertaining to Physical Description",
    "308" => "Notes Pertaining to Series",
    "310" => "Notes Pertaining to Binding and Availability",
    "311" => "Notes Pertaining to Linking Fields",
    "312" => "Notes Pertaining to Related Titles",
    "313" => "Notes Pertaining to Subject Access",
    "314" => "Notes Pertaining to Intellectual Responsibility",
    "315" => "Notes Pertaining to Material (or Type of Publication) Specific Information",
    "316" => "Note Relating to the Copy in Hand",
    "317" => "Provenance Note",
    "318" => "Action Note",
    "320" => "Internal Bibliographies/Indexes Note",
    "321" => "External Indexes/Abstracts/References Note",
    "322" => "Credits Note (Projected and Video Material and Sound Recordings)",
    "323" => "Cast Note (Projected and Video Material and Sound Recordings)",
    "324" => "Facsimile Note",
    "325" => "Reproduction Note",
    "326" => "Frequency Statement Note (Serials)",
    "327" => "Contents Note",
    "328" => "Dissertation (Thesis) Note",
    "330" => "Summary or Abstract",
    "332" => "Preferred Citation of Described Materials",
    "333" => "Users/Intended Audience Note",
    "336" => "Type of Electronic Resource Note",
    "337" => "System Requirements Note",
    "345" => "Acquisition Information Note",
    "410" => "Series",
    "411" => "Subseries",
    "421" => "Supplement",
    "422" => "Parent of Supplement",
    "423" => "Issued with",
    "430" => "Continues",
    "431" => "Continues in Part",
    "432" => "Supersedes",
    "433" => "Supersedes in Part",
    "434" => "Absorbed",
    "435" => "Absorbed in Part",
    "436" => "Formed by Merger of",
    "437" => "Separated From",
    "440" => "Continued by",
    "441" => "Continued in Part by",
    "442" => "Superseded by",
    "443" => "Superseded in Part by",
    "444" => "Absorbed by",
    "445" => "Absorbed in Part by",
    "446" => "Split into",
    "447" => "Merged with xxx to form",
    "448" => "Changed back to",
    "451" => "Other Edition in Same Medium",
    "452" => "Edition in a Different Medium",
    "453" => "Translated as",
    "454" => "Translation of",
    "455" => "Reproduction of",
    "456" => "Reproduced as",
    "461" => "Set Level",
    "462" => "Subset Level",
    "463" => "Piece Level",
    "464" => "Piece-Analytic Level",
    "470" => "Item reviewed",
    "481" => "Also Bound With this Volume",
    "482" => "Bound With",
    "488" => "Other Related Works",
    "500" => "Uniform Title",
    "501" => "Collective Uniform Title",
    "503" => "Uniform Conventional Heading",
    "510" => "Parallel Title Proper",
    "512" => "Cover Title",
    "513" => "Added Title-Page Title",
    "514" => "Caption Title",
    "515" => "Running Title",
    "516" => "Spine Title",
    "517" => "Other Variant Titles",
    "518" => "Title in Standard Modern Spelling",
    "520" => "Former Title (Serials)",
    "530" => "Key-Title (Serials)",
    "531" => "Abbreviated Title (Serials)",
    "532" => "Expanded Title",
    "540" => "Additional Title Supplied by Cataloguer",
    "541" => "Translated Title Supplied by Cataloguer",
    "545" => "Section Title",
    "600" => "Personal Name Used as Subject",
    "601" => "Corporate Body Name Used as Subject",
    "602" => "Family Name Used as Subject",
    "604" => "Name and Title Used as Subject",
    "605" => "Title Used as Subject",
    "606" => "Topical Name Used as Subject",
    "607" => "Geographical Name Used as Subject",
    "608" => "Form Heading",
    "610" => "Uncontrolled Subject Terms",
    "615" => "Subject Category (Provisional)",
    "620" => "Place Access",
    "626" => "[Technical Details Access (Electronic Resources) * Obsolete *]",
    "660" => "Geographic Area Code (GAC)",
    "661" => "Time Period Code",
    "670" => "PRECIS",
    "675" => "Universal Decimal Classification (UDC)",
    "676" => "Dewey Decimal Classification (DDC)",
    "680" => "Library of Congress Classification",
    "686" => "Other Class Numbers",
    "700" => "Personal Name - Primary Intellectual Responsibility",
    "701" => "Personal Name - Alternative Intellectual Responsibility",
    "702" => "Personal Name - Secondary Intellectual Responsibility",
    "710" => "Corporate Body Name - Primary Intellectual Responsibility",
    "711" => "Corporate Body Name - Alternative Intellectual Responsibility",
    "712" => "Corporate Body Name - Secondary Intellectual Responsibility",
    "720" => "Family Name - Primary Intellectual Responsibility",
    "721" => "Family Name - Alternative Intellectual Responsibility",
    "722" => "Family Name - Secondary Intellectual Responsibility",
    "730" => "Name - Intellectual Responsibility",
    "801" => "Originating Source",
    "802" => "ISSN Centre",
    "830" => "General Cataloguer's Note",
    "856" => "Electronic Location and Access",
    "886" => "Data Not Converted from Source Format"
  }

  UNIMARC_LEADER_POSITIONS = {
    5 => {
      :name => {:it => "Status del record", :en => "Record status"},
      :code => {
        "c" => {:it => "corretto",
                :en => "corrected record"},
        "d" => {:it => "cancellato",
                :en => "deleted record"},
        "n" => {:it => "nuovo",
                :en => "new record"},
        "o" => {:it => "record di livello inferiore di altro precedentemente fornito a livello più alto",
                :en => "previously issued higher level record"},
        "p" => {:it => "record precedentemente fornito incompleto (CIP)",
                :en => "previously issued as an incomplete, pre-publication record"}
      }
    },
    6 => {
      :name => {:it => "Tipo di record", :en => "Type of record"},
      :code => {
        "a" => {:it => "materiale a stampa",
                :en => "language materials, printed"},
        "b" => {:it => "materiale manoscritto",
                :en => "language materials, manuscript"},
        "c" => {:it => "partiture musicali a stampa",
                :en => "music scores, printed"},
        "d" => {:it => "partiture musicali manoscritte",
                :en => "music scores, manuscript"},
        "e" => {:it => "materiale cartografico a stampa",
                :en => "cartographic materials, printed"},
        "f" => {:it => "materiale cartografico manoscritto",
                :en => "cartographic materials, manuscript"},
        "g" => {:it => "materiali video e proiettato (film, filmine, diapositive, trasparenti, videoregistrazioni)",
                :en => "projected and video material (motion pictures, filmstrips, slides, transparencies, video recordings)"},
        "i" => {:it => "registrazioni sonore non musicali",
                :en => "sound recordings, nonmusical performance"},
        "j" => {:it => "registrazioni sonore musicali",
                :en => "sound recordings, musical performance"},
        "k" => {:it => "grafica bidimensionale (dipinti, disegni etc.)",
                :en => "two dimensional graphics (pictures, designs etc.)"},
        "l" => {:it => "risorsa elettronica",
                :en => "electronic resources"},
        "m" => {:it => "materiale misto",
                :en => "multimedia"},
        "r" => {:it => "manufatti tridimensionali o oggetti presenti in natura",
                :en => "three dimensional artefacts and realia"}
      }
    },
    7 => {
      :name => {:it => "Livello bibliografico", :en => "Bibliographic level"},
      :code => {
        "a" => {:it => "analitico (parte componente)", :en => "analytic (component part)"},
        "i" => {:it => "risorsa integrativa", :en => "integrative resource"},
        "m" => {:it => "monografia", :en => "monographic"},
        "s" => {:it => "periodico", :en => "serial"},
        "c" => {:it => "collezione", :en => "collection"},
      }
    },
    8 => {
      :name => {:it => "Livello gerarchico", :en => "Hierarchical level"},
      :code => {
        "#" => {:it => "non definito", :en => "hierarchical relationship undefined"},
        "0" => {:it => "senza relazione gerarchica", :en => "no hierarchical relationship"},
        "1" => {:it => "record di livello più alto", :en => "highest level record"},
        "2" => {:it => "record al di sotto del livello più alto", :en => "record below highest level (all levels below)"}
      }
    }
  }

  UNIMARC_LINK_FIELDS = {
    '423' => {:description => {:en => "Issued with", :it => "Pubblicato con"}},
    #'430' => {:description => {:en => "Continues", :it => "Continuazione di"}},
    '461' => {:description => {:en => "Set Level", :it => "Fa parte di"}}, # Legame all'insieme
    # TODO: il significato di 462 e 463 va interpretato in funzione dei link presenti nel record referenziato
    '462' => {:description => {:en => "Subset Level", :it => "Sottoinsieme"}}, # => comprende/fa parte di # => esempio IT\ICCU\PUV\0813936 + IT\ICCU\PUV\0813943
    '463' => {:description => {:en => "Piece Level", :it => "Unità singola"}}, # => comprende/fa parte di
    # TODO: trovare una traduzione migliore rispetto a "spoglio"
    '464' => {:description => {:en => "Piece-Analytic Level", :it => "Spoglio"}} # Legame all'unità singola analitica
  }


  UNIMARC_INTELLECTUAL_RESPONSABILITY_INDICATORS = {
    '700' => {
      :indicator_1 => {:meaning => {:en => "Not defined"}},
      :indicator_2 => {
        :name => {:en => "Form of Name"},
        :description => {:en => "This indicator specifies whether the name is entered under the first occurring name (forename) or in direct order or whether it is entered under a surname, family name, patronymic or equivalent, usually with inversion (EX 5)."},
        :code => {
          '0' => {:en => "Name entered under forename or direct order"},
          '1' => {:en => "Name entered under surname (family name, patronymic, etc.)"}
        }
      }
    },
    '701' => {:idem => '700'},
    '702' => {:idem => '700'}
  }

  # Appendix C
  UNIMARC_RELATOR_CODES =  {
     "660"=>
      {:description=>{:en=>"Person to whom letters are addressed."},
       :name=>{:en=>"Recipient of letters"}},
     "582"=>
      {:description=>
        {:en=>
          "The person or body that applied for a patent described in the record."},
       :name=>{:en=>"Patent applicant"}},
     "540"=>
      {:description=>
        {:en=>
          "Person or organization that supervises the compliance with the contract and is responsible for the report and controls its distribution. Sometimes referred to as the grantee, or controlling agency."},
       :name=>{:en=>"Monitor"}},
     "300"=>
      {:description=>
        {:en=>
          "Person responsible for the general management of the work or who supervised the production of the performance for stage, screen, or sound recording."},
       :name=>{:en=>"Director"}},
     "420"=>
      {:description=>
        {:en=>"Person in memory or honour of whom a book is donated."},
       :name=>{:en=>"Honoree"}},
     "760"=>{:name=>{:en=>"Wood-engraver"}},
     "640"=>
      {:description=>
        {:en=>
          "Corrector of printed matter only; for manuscripts use Corrector (270)."},
       :name=>{:en=>"Proof-reader"}},
     "400"=>
      {:description=>
        {:en=>
          "Person or agency that furnished financial support for the production of the work. For the person or agency that issued the contract for the production use Sponsor (723)."},
       :name=>{:en=>"Funder"}},
     "520"=>
      {:description=>{:en=>"Writer of the text of a song."},
       :name=>{:en=>"Lyricist"}},
     "740"=>
      {:description=>
        {:en=>"Person who designed the type face used in a particular book."},
       :name=>{:en=>"Type designer"}},
     "620"=>
      {:description=>{:en=>"Printer of illustrations or designs from plates."},
       :name=>{:en=>"Printer of plates"}},
     "584"=>
      {:description=>
        {:en=>
          "The person who invented the device or process covered by the patent described in the record."},
       :name=>{:en=>"Patent inventor"}},
     "005"=>
      {:description=>
        {:en=>
          "Person who principally exhibits acting skills in a musical or dramatic presentation or entertainment."},
       :name=>{:en=>"Actor"}},
     "500"=>
      {:description=>{:en=>"Signer of license, imprimatur, etc."},
       :name=>{:en=>"Licensor"}},
     "245"=>
      {:description=>
        {:en=>
          "Person or corporate body responsible for the original idea on which a work is based. This includes the scientific author of an audio-visual item and the conceptor of an advertisement."},
       :name=>{:en=>"Conceptor"}},
     "090"=>
      {:description=>
        {:en=>
          "The writer of dialogue or spoken commentary for a screenplay or sound recording."},
       :name=>{:en=>"Author of dialogue"}},
     "365"=>
      {:description=>
        {:en=>
          "Person in charge of the description and appraisal of the value of goods, particularly rare items, works of art, etc."},
       :name=>{:en=>"Expert"}},
     "720"=>
      {:description=>
        {:en=>
          "Use for signature which appears in a book without a presentation or other statement indicative of provenance."},
       :name=>{:en=>"Signer"}},
     "600"=>
      {:description=>
        {:en=>
          "(1) the person who took a still photograph. This relator may be used in a record for either the original photograph or for a reproduction in any medium; or, (2) the person responsible for the photography in a motion picture."},
       :name=>{:en=>"Photographer"}},
     "070"=>
      {:description=>
        {:en=>
          "Person or corporate body chiefly responsible for the creation of the intellectual or artistic content of a work. When more than one person or body jointly bears such responsibility, this code may be used in association with as many headings as is appropriate."},
       :name=>{:en=>"Author"}},
     "190"=>
      {:description=>
        {:en=>"Censor, bowdlerizer, expurgator, etc., official or private."},
       :name=>{:en=>"Censor"}},
     "721"=>
      {:description=>
        {:en=>
          "Person who uses his or her voice with or without musical accompaniment to produce music. A singer's performance may or may not include actual words."},
       :name=>{:en=>"Singer"}},
     "700"=>
      {:description=>
        {:en=>
          "Maker of penfacsimiles of printed matter and also an amanuensis or a writer of manuscripts proper."},
       :name=>{:en=>"Scribe"}},
     "170"=>{:name=>{:en=>"Calligrapher"}},
     "290"=>
      {:description=>
        {:en=>
          "The author of a dedication. The dedication may be a formal statement or it may be in epistolary or verse form."},
       :name=>{:en=>"Dedicator"}},
     "205"=>
      {:description=>
        {:en=>
          "Use only when a more precise function, represented by another code, cannot be used."},
       :name=>{:en=>"Collaborator"}},
     "050"=>
      {:description=>
        {:en=>
          "Person or organization to which a license for printing or publishing has been transferred."},
       :name=>{:en=>"Assignee"}},
     "587"=>
      {:description=>
        {:en=>
          "The person or body that was granted the patent described in the record."},
       :name=>{:en=>"Patentee"}},
     "545"=>
      {:description=>
        {:en=>
          "Person who performs music or contributes to the musical content of a work. Use when it is not possible or desirable to identify more precisely the person's function."},
       :name=>{:en=>"Musician"}},
     "390"=>
      {:description=>
        {:en=>
          "Person or organization owning an item at any time in the past. Includes a person or organization to whom the item was once presented as named in a statement inscribed by another person or organization. Person or body giving the item to present owner is designated as Donor (320)."},
       :name=>{:en=>"Former owner"}},
     "030"=>
      {:description=>
        {:en=>
          "One who transcribes a musical composition, usually for a different instrument or medium from that of the original; in an arrangement the musical substance remains essentially unchanged."},
       :name=>{:en=>"Arranger"}},
     "305"=>
      {:description=>
        {:en=>
          "Person who presents a thesis for a university or higher-level educational degree."},
       :name=>{:en=>"Dissertant"}},
     "150"=>{:name=>{:en=>"Bookplate designer"}},
     "072"=>
      {:description=>
        {:en=>
          "Person whose work is largely quoted or extracted in works to which he or she did not contribute directly. Such quotations are found particularly in exhibition catalogues, collections of photographs etc."},
       :name=>{:en=>"Author in quotations or text extracts"}},
     "270"=>
      {:description=>
        {:en=>
          "Scriptorium official who corrected the work of a scribe. For printed matter use proof-reader (640)."},
       :name=>{:en=>"Corrector"}},
     "723"=>{:name=>{:en=>"Sponsor"}},
     "010"=>
      {:description=>
        {:en=>
          "Writer who rewrites novels or stories for motion pictures or another audiovisual medium. For one who reworks a musical composition, usually for a different medium, use Arranger (030)."},
       :name=>{:en=>"Adapter"}},
     "130"=>
      {:description=>
        {:en=>
          "Person or corporate body responsible for the entire graphic design of a book, including arrangement of type and illustration, choice of materials, and process to be used."},
       :name=>{:en=>"Book designer"}},
     "250"=>
      {:description=>
        {:en=>
          "Person directing the group performing a musical work. Also, a choral director."},
       :name=>{:en=>"Conductor"}},
     "370"=>{:name=>{:en=>"Film editor"}},
     "490"=>
      {:description=>{:en=>"Original recipient of right to print or publish."},
       :name=>{:en=>"Licensee"}},
     "590"=>
      {:description=>
        {:en=>
          "Person acting or otherwise performing in a musical or dramatic presentation or entertainment. Use if more specific codes are not required, e.g. actor, dancer, musician, singer."},
       :name=>{:en=>"Performer"}},
     "110"=>{:name=>{:en=>"Binder"}},
     "230"=>
      {:description=>
        {:en=>
          "One who creates a musical work, usually a piece of music in manuscript or printed form."},
       :name=>{:en=>"Composer"}},
     "350"=>{:name=>{:en=>"Engraver"}},
     "470"=>{:name=>{:en=>"Interviewer"}},
     "725"=>
      {:description=>
        {:en=>"The agency responsible for issuing or enforcing a standard."},
       :name=>{:en=>"Standards body"}},
     "690"=>
      {:description=>{:en=>"Author of a screenplay."}, :name=>{:en=>"Scenarist"}},
     "570"=>
      {:description=>
        {:en=>
          "Use whenever a relator or relator code in a national format has no equivalent in UNIMARC."},
       :name=>{:en=>"Other"}},
     "210"=>
      {:description=>
        {:en=>
          "One who provides interpretation, analysis, or a discussion of the subject matter on a recording, motion picture, or other audiovisual medium."},
       :name=>{:en=>"Commentator"}},
     "330"=>
      {:description=>
        {:en=>
          "One to whom the authorship of a work has been dubiously or incorrectly ascribed."},
       :name=>{:en=>"Dubious author"}},
     "450"=>
      {:description=>{:en=>"Person who signs a presentation statement."},
       :name=>{:en=>"Inscriber"}},
     "075"=>
      {:description=>
        {:en=>
          "Use instead of Author of introduction, etc. (080) when the nature of the afterword etc. is completely different from that of the introduction, etc."},
       :name=>{:en=>"Author of afterword, postface, colophon, etc."}},
     "273"=>
      {:description=>
        {:en=>
          "Person who is responsible for conceiving and organizing an exhibition."},
       :name=>{:en=>"Curator of an exhibition"}},
     "705"=>
      {:description=>
        {:en=>"Use when the more general term Artist (040) is not required."},
       :name=>{:en=>"Sculptor"}},
     "670"=>
      {:description=>
        {:en=>
          "Person supervising the technical aspects of a sound or video recording session."},
       :name=>{:en=>"Recording engineer"}},
     "550"=>
      {:description=>
        {:en=>
          "Speaker delivering the narration in a motion picture, sound recording or other type of work."},
       :name=>{:en=>"Narrator"}},
     "310"=>
      {:description=>
        {:en=>
          "Agent or agency that has exclusive or shared marketing rights for an item."},
       :name=>{:en=>"Distributor"}},
     "430"=>{:name=>{:en=>"Illuminator"}},
     "295"=>
      {:description=>
        {:en=>
          "The body granting the degree for which the thesis or dissertation included in the item was presented."},
       :name=>{:en=>"Degree-grantor"}},
     "770"=>
      {:description=>
        {:en=>
          "Writer of significant material which accompanies a sound recording or other audiovisual material."},
       :name=>{:en=>"Writer of accompanying material"}},
     "727"=>
      {:description=>
        {:en=>
          "Person under whose supervision a degree candidate develops and presents a thesis, m\351moire, or text of a dissertation."},
       :name=>{:en=>"Thesis advisor"}},
     "650"=>{:name=>{:en=>"Publisher"}},
     "212"=>
      {:description=>
        {:en=>
          "One who writes commentary or explanatory notes about a text. For the writer of manuscript annotations in a printed book, use Annotator (020)."},
       :name=>{:en=>"Commentator for written text"}},
     "410"=>
      {:description=>
        {:en=>
          "Person responsible for the realization of the design in a medium from which an image (printed, displayed etc.) may be produced. If person who conceives the design (i.e. Illustrator (440)) also realizes it, codes for both functions may be used as needed."},
       :name=>{:en=>"Graphic technician"}},
     "530"=>{:name=>{:en=>"Metal-engraver"}},
     "275"=>
      {:description=>
        {:en=>
          "Person who principally exhibits dancing skills in a musical or dramatic presentation or entertainment."},
       :name=>{:en=>"Dancer"}},
     "750"=>
      {:description=>
        {:en=>
          "Person primarily responsible for choice and arrangement of type used in a book. If the person who selects and arranges type is also responsible for other aspects of the graphic design of a book, i.e. Book designer (130), codes for both functions may be needed."},
       :name=>{:en=>"Typographer"}},
     "651"=>{:name=>{:en=>"Publishing director"}},
     "630"=>
      {:description=>
        {:en=>
          "Person with final responsibility for the making of a motion picture, including business aspects, management of the productions, and the commercial success of the film."},
       :name=>{:en=>"Producer"}},
     "510"=>
      {:description=>
        {:en=>
          "Person who prepares the stone or grained plate for lithographic printing, including a graphic artist creating an original design while working directly on the surface from which printing will be done."},
       :name=>{:en=>"Lithographer"}},
     "255"=>
      {:description=>
        {:en=>
          "Professional person or organisation engaged specifically to provide an intellectual overview of a strategic or operational task and - by analysis, specification or instruction - to create or propose a cost-effective course of action or solution."},
       :name=>{:en=>"Consultant to a project"}},
     "730"=>
      {:description=>
        {:en=>
          "One who renders from one language into another, or from an older form of a language into the modern form, more or less closely following the original."},
       :name=>{:en=>"Translator"}},
     "673"=>
      {:description=>
        {:en=>
          "The person who directed the research or managed the project reported in the item."},
       :name=>{:en=>"Research Team Head"}},
     "610"=>
      {:description=>
        {:en=>"Printer of texts, whether from type or plates (e.g. stereotype)."},
       :name=>{:en=>"Printer"}},
     "595"=>
      {:description=>
        {:en=>
          "The corporate body responsible for performing the research reported in the item."},
       :name=>{:en=>"Performer of research"}},
     "080"=>
      {:description=>
        {:en=>
          "One who is the author of an introduction, preface, foreword, afterword, notes, other critical matter, etc., but who is not the chief author of the work. See also Author of afterword (075)."},
       :name=>{:en=>"Author of introduction, etc."}},
     "710"=>
      {:description=>
        {:en=>
          "Redactor, or other person responsible for expressing the views of a body, being responsible for their intellectual content."},
       :name=>{:en=>"Secretary"}},
     "695"=>
      {:description=>
        {:en=>
          "Person who brings scientific, pedagogical, or historical competence to the conception and realization of a work, particularly in the case of audio-visual items."},
       :name=>{:en=>"Scientific advisor"}},
     "060"=>
      {:description=>
        {:en=>
          "General relator for a name associated with or found in a book, which cannot be determined to be that of a Former owner (390) or other designated relator indicative of provenance."},
       :name=>{:en=>"Associated name"}},
     "180"=>{:name=>{:en=>"Cartographer"}},
     "675"=>
      {:description=>
        {:en=>
          "Person or corporate body responsible for the review of a book, motion picture, performance, etc."},
       :name=>{:en=>"Reviewer"}},
     "555"=>
      {:description=>
        {:en=>
          "A person solely or partly responsible for opposing a thesis or dissertation."},
       :name=>{:en=>"Opponent"}},
     "280"=>
      {:description=>
        {:en=>
          "Person or organization to whom a book or manuscript is dedicated (not the recipient of a gift). The dedication may be formal (appearing in the document) or informal (copy-specific). In the latter case the field containing the 280 code will have a subfield $5 for the institution holding the copy."},
       :name=>{:en=>"Dedicatee"}},
     "040"=>
      {:description=>{:en=>"Painter, sculptor, etc., of a work."},
       :name=>{:en=>"Artist"}},
     "160"=>{:name=>{:en=>"Bookseller"}},
     "020"=>
      {:description=>
        {:en=>
          "Writer of manuscript annotations in a printed book. For the writer of commentary or explanatory notes about a text, use Commentator for written text (212)."},
       :name=>{:en=>"Annotator"}},
     "140"=>{:name=>{:en=>"Bookjacket designer"}},
     "260"=>{:name=>{:en=>"Copyright holder"}},
     "380"=>{:name=>{:en=>"Forger"}},
     "755"=>
      {:description=>
        {:en=>
          "Person who principally exhibits singing skills in a musical or dramatic presentation or entertainment."},
       :name=>{:en=>"Vocalist"}},
     "677"=>
      {:description=>
        {:en=>
          "A member of a research team responsible for the research reported in the item."},
       :name=>{:en=>"Research Team Member"}},
     "635"=>
      {:description=>
        {:en=>
          "Person or corporate body responsible for the creation of computer program design documents, source code, or machine-executable digital files and supporting documentation."},
       :name=>{:en=>"Programmer"}},
     "557"=>
      {:description=>
        {:en=>
          "A person or body responsible for organising the meeting reported to the item."},
       :name=>{:en=>"Organiser of meeting"}},
     "120"=>{:name=>{:en=>"Binding designer"}},
     "240"=>{:name=>{:en=>"Compositor"}},
     "360"=>{:name=>{:en=>"Etcher"}},
     "480"=>
      {:description=>{:en=>"Writer of the text of an opera, oratorio, etc."},
       :name=>{:en=>"Librettist"}},
     "580"=>{:name=>{:en=>"Papermaker"}},
     "100"=>
      {:description=>
        {:en=>
          "One who is the author of the work upon which the work reflected in the catalogue record is based in whole or in part. This relator may be appropriate in records for adaptations, indexes, continuations and sequels by different authors, concordances, etc."},
       :name=>{:en=>"Bibliographic antecedent"}},
     "220"=>
      {:description=>
        {:en=>
          "One who produces a collection by selecting and putting together matter from works of various persons or bodies. Also, one who selects and puts together in one publication matter from the works of one person or body."},
       :name=>{:en=>"Compiler"}},
     "340"=>
      {:description=>
        {:en=>
          "One who prepares for publication a work not his own. The editorial work may be either technical or intellectual."},
       :name=>{:en=>"Editor"}},
     "460"=>{:name=>{:en=>"Interviewee"}},
     "680"=>{:name=>{:en=>"Rubricator"}},
     "560"=>
      {:description=>
        {:en=>
          "Author or agency performing the work, i.e. the name of a person or organization associated with the intellectual content of the work. Includes person named in the work as investigator or principal investigator. This category does not include the publisher or personal affiliation, or sponsor except where it is also the corporate author."},
       :name=>{:en=>"Originator"}},
     "200"=>{:name=>{:en=>"Choreographer"}},
     "320"=>
      {:description=>
        {:en=>
          "Donor of book to present owner. Donor to previous owner is designated as Former owner (390)."},
       :name=>{:en=>"Donor"}},
     "440"=>
      {:description=>{:en=>"Person who conceives a design or illustration."},
       :name=>{:en=>"Illustrator"}},
     "065"=>
      {:description=>
        {:en=>
          "Person or corporate body in charge of the estimation and public auctioning of goods, particularly books, artistic works, etc."},
       :name=>{:en=>"Auctioneer"}}}
    {"660"=>
      {:description=>{:en=>"Person to whom letters are addressed."},
       :name=>{:en=>"Recipient of letters"}},
     "582"=>
      {:description=>
        {:en=>
          "The person or body that applied for a patent described in the record."},
       :name=>{:en=>"Patent applicant"}},
     "540"=>
      {:description=>
        {:en=>
          "Person or organization that supervises the compliance with the contract and is responsible for the report and controls its distribution. Sometimes referred to as the grantee, or controlling agency."},
       :name=>{:en=>"Monitor"}},
     "300"=>
      {:description=>
        {:en=>
          "Person responsible for the general management of the work or who supervised the production of the performance for stage, screen, or sound recording."},
       :name=>{:en=>"Director"}},
     "420"=>
      {:description=>
        {:en=>"Person in memory or honour of whom a book is donated."},
       :name=>{:en=>"Honoree"}},
     "760"=>{:name=>{:en=>"Wood-engraver"}},
     "640"=>
      {:description=>
        {:en=>
          "Corrector of printed matter only; for manuscripts use Corrector (270)."},
       :name=>{:en=>"Proof-reader"}},
     "400"=>
      {:description=>
        {:en=>
          "Person or agency that furnished financial support for the production of the work. For the person or agency that issued the contract for the production use Sponsor (723)."},
       :name=>{:en=>"Funder"}},
     "520"=>
      {:description=>{:en=>"Writer of the text of a song."},
       :name=>{:en=>"Lyricist"}},
     "740"=>
      {:description=>
        {:en=>"Person who designed the type face used in a particular book."},
       :name=>{:en=>"Type designer"}},
     "620"=>
      {:description=>{:en=>"Printer of illustrations or designs from plates."},
       :name=>{:en=>"Printer of plates"}},
     "584"=>
      {:description=>
        {:en=>
          "The person who invented the device or process covered by the patent described in the record."},
       :name=>{:en=>"Patent inventor"}},
     "005"=>
      {:description=>
        {:en=>
          "Person who principally exhibits acting skills in a musical or dramatic presentation or entertainment."},
       :name=>{:en=>"Actor"}},
     "500"=>
      {:description=>{:en=>"Signer of license, imprimatur, etc."},
       :name=>{:en=>"Licensor"}},
     "245"=>
      {:description=>
        {:en=>
          "Person or corporate body responsible for the original idea on which a work is based. This includes the scientific author of an audio-visual item and the conceptor of an advertisement."},
       :name=>{:en=>"Conceptor"}},
     "090"=>
      {:description=>
        {:en=>
          "The writer of dialogue or spoken commentary for a screenplay or sound recording."},
       :name=>{:en=>"Author of dialogue"}},
     "365"=>
      {:description=>
        {:en=>
          "Person in charge of the description and appraisal of the value of goods, particularly rare items, works of art, etc."},
       :name=>{:en=>"Expert"}},
     "720"=>
      {:description=>
        {:en=>
          "Use for signature which appears in a book without a presentation or other statement indicative of provenance."},
       :name=>{:en=>"Signer"}},
     "600"=>
      {:description=>
        {:en=>
          "(1) the person who took a still photograph. This relator may be used in a record for either the original photograph or for a reproduction in any medium; or, (2) the person responsible for the photography in a motion picture."},
       :name=>{:en=>"Photographer"}},
     "070"=>
      {:description=>
        {:en=>
          "Person or corporate body chiefly responsible for the creation of the intellectual or artistic content of a work. When more than one person or body jointly bears such responsibility, this code may be used in association with as many headings as is appropriate."},
       :name=>{:en=>"Author"}},
     "190"=>
      {:description=>
        {:en=>"Censor, bowdlerizer, expurgator, etc., official or private."},
       :name=>{:en=>"Censor"}},
     "721"=>
      {:description=>
        {:en=>
          "Person who uses his or her voice with or without musical accompaniment to produce music. A singer's performance may or may not include actual words."},
       :name=>{:en=>"Singer"}},
     "700"=>
      {:description=>
        {:en=>
          "Maker of penfacsimiles of printed matter and also an amanuensis or a writer of manuscripts proper."},
       :name=>{:en=>"Scribe"}},
     "170"=>{:name=>{:en=>"Calligrapher"}},
     "290"=>
      {:description=>
        {:en=>
          "The author of a dedication. The dedication may be a formal statement or it may be in epistolary or verse form."},
       :name=>{:en=>"Dedicator"}},
     "205"=>
      {:description=>
        {:en=>
          "Use only when a more precise function, represented by another code, cannot be used."},
       :name=>{:en=>"Collaborator"}},
     "050"=>
      {:description=>
        {:en=>
          "Person or organization to which a license for printing or publishing has been transferred."},
       :name=>{:en=>"Assignee"}},
     "587"=>
      {:description=>
        {:en=>
          "The person or body that was granted the patent described in the record."},
       :name=>{:en=>"Patentee"}},
     "545"=>
      {:description=>
        {:en=>
          "Person who performs music or contributes to the musical content of a work. Use when it is not possible or desirable to identify more precisely the person's function."},
       :name=>{:en=>"Musician"}},
     "390"=>
      {:description=>
        {:en=>
          "Person or organization owning an item at any time in the past. Includes a person or organization to whom the item was once presented as named in a statement inscribed by another person or organization. Person or body giving the item to present owner is designated as Donor (320)."},
       :name=>{:en=>"Former owner"}},
     "030"=>
      {:description=>
        {:en=>
          "One who transcribes a musical composition, usually for a different instrument or medium from that of the original; in an arrangement the musical substance remains essentially unchanged."},
       :name=>{:en=>"Arranger"}},
     "305"=>
      {:description=>
        {:en=>
          "Person who presents a thesis for a university or higher-level educational degree."},
       :name=>{:en=>"Dissertant"}},
     "150"=>{:name=>{:en=>"Bookplate designer"}},
     "072"=>
      {:description=>
        {:en=>
          "Person whose work is largely quoted or extracted in works to which he or she did not contribute directly. Such quotations are found particularly in exhibition catalogues, collections of photographs etc."},
       :name=>{:en=>"Author in quotations or text extracts"}},
     "270"=>
      {:description=>
        {:en=>
          "Scriptorium official who corrected the work of a scribe. For printed matter use proof-reader (640)."},
       :name=>{:en=>"Corrector"}},
     "723"=>{:name=>{:en=>"Sponsor"}},
     "010"=>
      {:description=>
        {:en=>
          "Writer who rewrites novels or stories for motion pictures or another audiovisual medium. For one who reworks a musical composition, usually for a different medium, use Arranger (030)."},
       :name=>{:en=>"Adapter"}},
     "130"=>
      {:description=>
        {:en=>
          "Person or corporate body responsible for the entire graphic design of a book, including arrangement of type and illustration, choice of materials, and process to be used."},
       :name=>{:en=>"Book designer"}},
     "250"=>
      {:description=>
        {:en=>
          "Person directing the group performing a musical work. Also, a choral director."},
       :name=>{:en=>"Conductor"}},
     "370"=>{:name=>{:en=>"Film editor"}},
     "490"=>
      {:description=>{:en=>"Original recipient of right to print or publish."},
       :name=>{:en=>"Licensee"}},
     "590"=>
      {:description=>
        {:en=>
          "Person acting or otherwise performing in a musical or dramatic presentation or entertainment. Use if more specific codes are not required, e.g. actor, dancer, musician, singer."},
       :name=>{:en=>"Performer"}},
     "110"=>{:name=>{:en=>"Binder"}},
     "230"=>
      {:description=>
        {:en=>
          "One who creates a musical work, usually a piece of music in manuscript or printed form."},
       :name=>{:en=>"Composer"}},
     "350"=>{:name=>{:en=>"Engraver"}},
     "470"=>{:name=>{:en=>"Interviewer"}},
     "725"=>
      {:description=>
        {:en=>"The agency responsible for issuing or enforcing a standard."},
       :name=>{:en=>"Standards body"}},
     "690"=>
      {:description=>{:en=>"Author of a screenplay."}, :name=>{:en=>"Scenarist"}},
     "570"=>
      {:description=>
        {:en=>
          "Use whenever a relator or relator code in a national format has no equivalent in UNIMARC."},
       :name=>{:en=>"Other"}},
     "210"=>
      {:description=>
        {:en=>
          "One who provides interpretation, analysis, or a discussion of the subject matter on a recording, motion picture, or other audiovisual medium."},
       :name=>{:en=>"Commentator"}},
     "330"=>
      {:description=>
        {:en=>
          "One to whom the authorship of a work has been dubiously or incorrectly ascribed."},
       :name=>{:en=>"Dubious author"}},
     "450"=>
      {:description=>{:en=>"Person who signs a presentation statement."},
       :name=>{:en=>"Inscriber"}},
     "075"=>
      {:description=>
        {:en=>
          "Use instead of Author of introduction, etc. (080) when the nature of the afterword etc. is completely different from that of the introduction, etc."},
       :name=>{:en=>"Author of afterword, postface, colophon, etc."}},
     "273"=>
      {:description=>
        {:en=>
          "Person who is responsible for conceiving and organizing an exhibition."},
       :name=>{:en=>"Curator of an exhibition"}},
     "705"=>
      {:description=>
        {:en=>"Use when the more general term Artist (040) is not required."},
       :name=>{:en=>"Sculptor"}},
     "670"=>
      {:description=>
        {:en=>
          "Person supervising the technical aspects of a sound or video recording session."},
       :name=>{:en=>"Recording engineer"}},
     "550"=>
      {:description=>
        {:en=>
          "Speaker delivering the narration in a motion picture, sound recording or other type of work."},
       :name=>{:en=>"Narrator"}},
     "310"=>
      {:description=>
        {:en=>
          "Agent or agency that has exclusive or shared marketing rights for an item."},
       :name=>{:en=>"Distributor"}},
     "430"=>{:name=>{:en=>"Illuminator"}},
     "295"=>
      {:description=>
        {:en=>
          "The body granting the degree for which the thesis or dissertation included in the item was presented."},
       :name=>{:en=>"Degree-grantor"}},
     "770"=>
      {:description=>
        {:en=>
          "Writer of significant material which accompanies a sound recording or other audiovisual material."},
       :name=>{:en=>"Writer of accompanying material"}},
     "727"=>
      {:description=>
        {:en=>
          "Person under whose supervision a degree candidate develops and presents a thesis, m\351moire, or text of a dissertation."},
       :name=>{:en=>"Thesis advisor"}},
     "650"=>{:name=>{:en=>"Publisher"}},
     "212"=>
      {:description=>
        {:en=>
          "One who writes commentary or explanatory notes about a text. For the writer of manuscript annotations in a printed book, use Annotator (020)."},
       :name=>{:en=>"Commentator for written text"}},
     "410"=>
      {:description=>
        {:en=>
          "Person responsible for the realization of the design in a medium from which an image (printed, displayed etc.) may be produced. If person who conceives the design (i.e. Illustrator (440)) also realizes it, codes for both functions may be used as needed."},
       :name=>{:en=>"Graphic technician"}},
     "530"=>{:name=>{:en=>"Metal-engraver"}},
     "275"=>
      {:description=>
        {:en=>
          "Person who principally exhibits dancing skills in a musical or dramatic presentation or entertainment."},
       :name=>{:en=>"Dancer"}},
     "750"=>
      {:description=>
        {:en=>
          "Person primarily responsible for choice and arrangement of type used in a book. If the person who selects and arranges type is also responsible for other aspects of the graphic design of a book, i.e. Book designer (130), codes for both functions may be needed."},
       :name=>{:en=>"Typographer"}},
     "651"=>{:name=>{:en=>"Publishing director"}},
     "630"=>
      {:description=>
        {:en=>
          "Person with final responsibility for the making of a motion picture, including business aspects, management of the productions, and the commercial success of the film."},
       :name=>{:en=>"Producer"}},
     "510"=>
      {:description=>
        {:en=>
          "Person who prepares the stone or grained plate for lithographic printing, including a graphic artist creating an original design while working directly on the surface from which printing will be done."},
       :name=>{:en=>"Lithographer"}},
     "255"=>
      {:description=>
        {:en=>
          "Professional person or organisation engaged specifically to provide an intellectual overview of a strategic or operational task and - by analysis, specification or instruction - to create or propose a cost-effective course of action or solution."},
       :name=>{:en=>"Consultant to a project"}},
     "730"=>
      {:description=>
        {:en=>
          "One who renders from one language into another, or from an older form of a language into the modern form, more or less closely following the original."},
       :name=>{:en=>"Translator"}},
     "673"=>
      {:description=>
        {:en=>
          "The person who directed the research or managed the project reported in the item."},
       :name=>{:en=>"Research Team Head"}},
     "610"=>
      {:description=>
        {:en=>"Printer of texts, whether from type or plates (e.g. stereotype)."},
       :name=>{:en=>"Printer"}},
     "595"=>
      {:description=>
        {:en=>
          "The corporate body responsible for performing the research reported in the item."},
       :name=>{:en=>"Performer of research"}},
     "080"=>
      {:description=>
        {:en=>
          "One who is the author of an introduction, preface, foreword, afterword, notes, other critical matter, etc., but who is not the chief author of the work. See also Author of afterword (075)."},
       :name=>{:en=>"Author of introduction, etc."}},
     "710"=>
      {:description=>
        {:en=>
          "Redactor, or other person responsible for expressing the views of a body, being responsible for their intellectual content."},
       :name=>{:en=>"Secretary"}},
     "695"=>
      {:description=>
        {:en=>
          "Person who brings scientific, pedagogical, or historical competence to the conception and realization of a work, particularly in the case of audio-visual items."},
       :name=>{:en=>"Scientific advisor"}},
     "060"=>
      {:description=>
        {:en=>
          "General relator for a name associated with or found in a book, which cannot be determined to be that of a Former owner (390) or other designated relator indicative of provenance."},
       :name=>{:en=>"Associated name"}},
     "180"=>{:name=>{:en=>"Cartographer"}},
     "675"=>
      {:description=>
        {:en=>
          "Person or corporate body responsible for the review of a book, motion picture, performance, etc."},
       :name=>{:en=>"Reviewer"}},
     "555"=>
      {:description=>
        {:en=>
          "A person solely or partly responsible for opposing a thesis or dissertation."},
       :name=>{:en=>"Opponent"}},
     "280"=>
      {:description=>
        {:en=>
          "Person or organization to whom a book or manuscript is dedicated (not the recipient of a gift). The dedication may be formal (appearing in the document) or informal (copy-specific). In the latter case the field containing the 280 code will have a subfield $5 for the institution holding the copy."},
       :name=>{:en=>"Dedicatee"}},
     "040"=>
      {:description=>{:en=>"Painter, sculptor, etc., of a work."},
       :name=>{:en=>"Artist"}},
     "160"=>{:name=>{:en=>"Bookseller"}},
     "020"=>
      {:description=>
        {:en=>
          "Writer of manuscript annotations in a printed book. For the writer of commentary or explanatory notes about a text, use Commentator for written text (212)."},
       :name=>{:en=>"Annotator"}},
     "140"=>{:name=>{:en=>"Bookjacket designer"}},
     "260"=>{:name=>{:en=>"Copyright holder"}},
     "380"=>{:name=>{:en=>"Forger"}},
     "755"=>
      {:description=>
        {:en=>
          "Person who principally exhibits singing skills in a musical or dramatic presentation or entertainment."},
       :name=>{:en=>"Vocalist"}},
     "677"=>
      {:description=>
        {:en=>
          "A member of a research team responsible for the research reported in the item."},
       :name=>{:en=>"Research Team Member"}},
     "635"=>
      {:description=>
        {:en=>
          "Person or corporate body responsible for the creation of computer program design documents, source code, or machine-executable digital files and supporting documentation."},
       :name=>{:en=>"Programmer"}},
     "557"=>
      {:description=>
        {:en=>
          "A person or body responsible for organising the meeting reported to the item."},
       :name=>{:en=>"Organiser of meeting"}},
     "120"=>{:name=>{:en=>"Binding designer"}},
     "240"=>{:name=>{:en=>"Compositor"}},
     "360"=>{:name=>{:en=>"Etcher"}},
     "480"=>
      {:description=>{:en=>"Writer of the text of an opera, oratorio, etc."},
       :name=>{:en=>"Librettist"}},
     "580"=>{:name=>{:en=>"Papermaker"}},
     "100"=>
      {:description=>
        {:en=>
          "One who is the author of the work upon which the work reflected in the catalogue record is based in whole or in part. This relator may be appropriate in records for adaptations, indexes, continuations and sequels by different authors, concordances, etc."},
       :name=>{:en=>"Bibliographic antecedent"}},
     "220"=>
      {:description=>
        {:en=>
          "One who produces a collection by selecting and putting together matter from works of various persons or bodies. Also, one who selects and puts together in one publication matter from the works of one person or body."},
       :name=>{:en=>"Compiler"}},
     "340"=>
      {:description=>
        {:en=>
          "One who prepares for publication a work not his own. The editorial work may be either technical or intellectual."},
       :name=>{:en=>"Editor"}},
     "460"=>{:name=>{:en=>"Interviewee"}},
     "680"=>{:name=>{:en=>"Rubricator"}},
     "560"=>
      {:description=>
        {:en=>
          "Author or agency performing the work, i.e. the name of a person or organization associated with the intellectual content of the work. Includes person named in the work as investigator or principal investigator. This category does not include the publisher or personal affiliation, or sponsor except where it is also the corporate author."},
       :name=>{:en=>"Originator"}},
     "200"=>{:name=>{:en=>"Choreographer"}},
     "320"=>
      {:description=>
        {:en=>
          "Donor of book to present owner. Donor to previous owner is designated as Former owner (390)."},
       :name=>{:en=>"Donor"}},
     "440"=>
      {:description=>{:en=>"Person who conceives a design or illustration."},
       :name=>{:en=>"Illustrator"}},
     "065"=>
      {:description=>
        {:en=>
          "Person or corporate body in charge of the estimation and public auctioning of goods, particularly books, artistic works, etc."},
       :name=>{:en=>"Auctioneer"}}
   }




  # BIB 1 - SEMANTICS ATTRIBUTE SET
  # http://www.loc.gov/z3950/agency/bib1.html
  # here a custom selection
  #    "Title"                          => 4    , #   Title
  #    "Author"                         => 1003 , #    Author-name
  #    "Date"                           => 30   , #   Date
  #    "Publisher"                      => 1018 , #    Name-publisher
  #    "Subject heading"                => 21   , #   Subject
  #    "Author-title"                   => 1000 , #    Author-name-and-title
  #    "Author-Title-Subject"           => 1036   #    Author-Title-Subject
  #    "ISBN"                           => 7    , #   Identifier-ISBN
  #    "ISSN"                           => 8    , #   Identifier-ISSN
  #    "Dewey classification"           => 13   , #   Classification-Dewey
  #    "Any"                            => 1016 , #    Any
  BIB_1_ATTRIBUTES = {
    #Use                            Value    Reference to Group Name Used in Table 2
    #-------------------------------------------------------------------------------
    "Personal name"                  => 1    , #   Name-personal
    "Corporate name"                 => 2    , #   Name-corporate
    "Conference name"                => 3    , #   Name-conference
    "Title"                          => 4    , #   Title
    "Title series"                   => 5    , #   Title-series
    "Title uniform"                  => 6    , #   Title-uniform
    "ISBN"                           => 7    , #   Identifier-ISBN
    "ISSN"                           => 8    , #   Identifier-ISSN
    "LC card number"                 => 9    , #   Control number-LC
    "BNB card number"                => 10   , #   Control number-BNB
    "BGF(sic) number"                => 11   , #   Control number-BNF
    "Local number"                   => 12   , #   Control number-local
    "Dewey classification"           => 13   , #   Classification-Dewey
    "UDC classification"             => 14   , #   Classification-UDC
    "Bliss classification"           => 15   , #   Classification-Bliss
    "LC call number"                 => 16   , #   Classification-LC
    "NLM call number"                => 17   , #   Classification-NLM
    "NAL call number"                => 18   , #   Classification-NAL
    "MOS call number"                => 19   , #   Classification-MOS
    "Local classification"           => 20   , #   Classification-local
    "Subject heading"                => 21   , #   Subject
    "Subject Rameau"                 => 22   , #   Subject-RAMEAU
    "BDI index subject"              => 23   , #   Subject-BDI
    "INSPEC subject"                 => 24   , #   Subject-INSPEC
    "MESH subject"                   => 25   , #   Subject-MESH
    "PA subject"                     => 26   , #   Subject-PA
    "LC subject heading"             => 27   , #   Subject-LC
    "RVM subject heading"            => 28   , #   Subject-RVM
    "Local subject index"            => 29   , #   Subject-local
    "Date"                           => 30   , #   Date
    "Date of publication"            => 31   , #   Date-publication
    "Date of acquisition"            => 32   , #   Date-acquisition
    "Title-key"                      => 33   , #   Title-key
    "Title collective"               => 34   , #   Title-collective
    "Title parallel"                 => 35   , #   Title-parallel
    "Title cover"                    => 36   , #   Title-cover
    "Title added-title-page"         => 37   , #   Title-added-title-page
    "Title caption"                  => 38   , #   Title-caption
    "Title running"                  => 39   , #   Title-running
    "Title spine"                    => 40   , #   Title-spine
    "Title other variant"            => 41   , #   Title-other-variant
    "Title former"                   => 42   , #   Title-former
    "Title abbreviated"              => 43   , #   Title-abbreviated
    "Title expanded"                 => 44   , #   Title-expanded
    "Subject PRECIS"                 => 45   , #   Subject-PRECIS
    "Subject RSWK"                   => 46   , #   Subject-RSWK
    "Subject subdivision"            => 47   , #   Subject-subdivision
    "Number natl bibliography"       => 48   , #   Identifier-national-bibliography
    "Number legal deposit"           => 49   , #   Identifier-legal-deposit
    "Number govt publication"        => 50   , #   Classification-government-publication
    "Number publisher for music"     => 51   , #   Identifier-publisher-for-music
    "Number DB"                      => 52   , #   Control-number-DB
    "Number local call"              => 53   , #   Identifier-local-call
    "Code--language"                 => 54   , #   Code-language
    "Code--geographic area"          => 55   , #   Code-geographic-area
    "Code--institution"              => 56   , #   Code-institution
    "Name and title"                 => 57   , #   Name and title
    "Name geographic"                => 58   , #   Name-geographic
    "Place publication"              => 59   , #   Name-geographic-place-publication
    "CODEN"                          => 60   , #   Identifier-CODEN
    "Microform generation"           => 61   , #   Code-microform-generation
    "Abstract"                       => 62   , #   Abstract
    "Note"                           => 63   , #   Note
    "Author-title"                   => 1000 , #    Author-name-and-title
    "Record type"                    => 1001 , #    Code-record-type
    "Name"                           => 1002 , #    Name
    "Author"                         => 1003 , #    Author-name
    "Author-name personal"           => 1004 , #    Author-name-personal
    "Author-name corporate"          => 1005 , #    Author-name-corporate
    "Author-name conference"         => 1006 , #    Author-name-conference
    "Identifier--standard"           => 1007 , #    Identifier-standard
    "Subject--LC children's"         => 1008 , #    Subject-LC-children's
    "Subject name--personal"         => 1009 , #    Subject-name-personal
    "Body of text"                   => 1010 , #    Body of text
    "Date/time added to database"    => 1011 , #    Date/time added to database
    "Date/time last modified"        => 1012 , #    Date/time last modified
    "Authority/format identifier"    => 1013 , #    Identifier-authority/format
    "Concept-text"                   => 1014 , #    Concept-text
    "Concept-reference"              => 1015 , #    Concept-reference
    "Any"                            => 1016 , #    Any
    "Server choice"                  => 1017 , #    Server-choice
    "Publisher"                      => 1018 , #    Name-publisher
    "Record source"                  => 1019 , #    Record-source
    "Editor"                         => 1020 , #    Name-editor
    "Bib-level"                      => 1021 , #    Code-bib-level
    "Geographic class"               => 1022 , #    Code-geographic-class
    "Indexed by"                     => 1023 , #    Indexed-by
    "Map scale"                      => 1024 , #    Code-map-scale
    "Music key"                      => 1025 , #    Music-key
    "Related periodical"             => 1026 , #    Title-related-periodical
    "Report number"                  => 1027 , #    Identifier-report
    "Stock number"                   => 1028 , #    Identifier-stock
    "Thematic number"                => 1030 , #    Identifier-thematic
    "Material type"                  => 1031 , #    Material-type
    "Doc ID"                         => 1032 , #    Identifier-document
    "Host item"                      => 1033 , #    Title-host-item
    "Content type"                   => 1034 , #    Content-type
    "Anywhere"                       => 1035 , #    Anywhere
    "Author-Title-Subject"           => 1036   #    Author-Title-Subject
  }

  OPAC_SBN_DUBLIN_CORE_TO_BIB1_MAPPING = {
    'title'       => 1097,
    'creator'     => 1098,
    'subject'     => 1099,
    'description' => 1100,
    'publisher'   => 1101,
    'contributor' => 1106,
    'date'        => 1102,
    'type'        => 1103,
    'format'      => 1107,
    'identifier'  => 1104,
    'source'      => 1108,
    'language'    => 1105,
    'relation'    => 1109,
    'coverage'    => 1110,
    'rights'      => 1111
  }

  DUBLIN_CORE_TO_UNIMARC = {
    "title"        => [ "200 $a Title Proper",
                        "200 $e Other Title Information (for subtitle)",
                        "517 $a Other Variant Titles (for other titles)"],
    "creator"      => [ "700 $a Personal Name - Primary Intellectual Responsibility",
                        "701 $a Personal Name - Alternative Intellectual Responsibility",
                        "710 $a Corporate Body Name - Primary Intellectual Responsibility",
                        "711 $a Corporate Body Name - Alternative Intellectual Responsibility",
                        "200 $f First Statement of Responsibility"],
    "subject"      => [ "610 $a Uncontrolled Subject Terms",
                        "606 Topical Name Used as Subject (for LCSH and MeSH)",
                        "675 UDC",
                        "676 DDC",
                        "680 LCC",
                        "686 Other Classification Systems"],
    "description"  => [ "330 $a Summary or Abstract"],
    "publisher"    => [ "210 $c Name of Publisher, Distributor, etc."],
    "contributors" => [ "701 $a Personal Name - Alternative Intellectual Responsibility",
                        "711 $a Corporate Body Name - Alternative Intellectual Responsibility",
                        "200 $g Subsequent Statement of Responsibility (if role known)"],
    "date"         => [ "210 $d Date of Publication, Distribution, etc."],
    "type"         => [ "608 Form, Genre or Physical Characteristics Heading"],
    "format"       => [ "336 $a Type of Computer File (provisional)"],
    "identifier"   => [ "001 (mandatory for UNIMARC)",
                        "010 (ISBN)",
                        "011 (ISSN)",
                        "020 (National Bibliography Number)",
                        "300 $a General Note (for URL)"],
    "source"       => [ "324 Original Version Note"],
    "language"     => [ "101 Language of the Item",
                        "300 General Note"],
    "relation"     => [ "300 General Note"],
    "coverage"     => [ "300 General Note"],
    "rights"       => [ "300 General Note"]
  }

  UNIMARC_TO_DUBLIN_CORE = {
    '001'     => ['bid',         "Identifier (mandatory for UNIMARC)"],
    '010'     => ['isbn',         "ISBN"],
    '011'     => ['issn',         "ISSN"],
    '020'     => [ nil,           "National Bibliography Number"],
    '101'     => ['language',     "Language of the Item"],
    '200 $a'  => ['title',        "Title Proper"],
    '200 $e'  => ['title',        "Other Title Information (for subtitle)"],
    '200 $f'  => ['creator',      "First Statement of Responsibility"],
    '200 $g'  => ['contributor',  "Subsequent Statement of Responsibility (if role known)"],
    '210 $c'  => ['publisher',    "Name of Publisher, Distributor, etc."],
    '210 $d'  => ['date',         "Date of Publication, Distribution, etc."],
    '300'     => [ nil,           "General Note"],
    '300 $a'  => [ nil,           "General Note (for URL)"],
    '324'     => ['source',       "Original Version Note"],
    '330 $a'  => ['description',  "Summary or Abstract"],
    '336 $a'  => ['format',       "Type of Computer File (provisional)"],
    '517 $a'  => ['title',        "Other Variant Titles (for other titles)"],
    '606'     => ['subject',      "Topical Name Used as Subject (for LCSH and MeSH)"],
    '608'     => ['type',         "Form, Genre or Physical Characteristics Heading"],
    '610 $a'  => ['subject',      "Uncontrolled Subject Terms"],
    '675'     => ['subject',      "UDC"],
    '676'     => ['subject',      "DDC"],
    '680'     => ['subject',      "LCC"],
    '686'     => ['subject',      "Other Classification Systems"],
    '700 $a'  => ['creator',      "Personal Name - Primary Intellectual Responsibility"],
    '701 $a'  => ['contributor',  "Personal Name - Alternative Intellectual Responsibility"],
    '710 $a'  => ['creator',      "Corporate Body Name - Primary Intellectual Responsibility"],
    '711 $a'  => ['contributor',  "Corporate Body Name - Alternative Intellectual Responsibility"],
  }

  PROPERTIES_TO_UNIMARC = {
    # type 1 # get_value_from_unimarc_flat_field
    'bid'        => '001',
    'isbn'        => '010',
    'issn'        => '011',
    'source'      => '324',

    # type 2: # get_value_from_multiple_unimarc_subfields
    'title'       => [{'200' => '$a'}, {'200' => '$e'}, {'200' => '$f'}, {'200' => '$g'}],
    'date'        => [{'210' => '$d'}],
    'string_date' => [{'210' => '$d'}],
    'description' => [{'330' => '$a'}],

    # type 3: # get_object_attribute_from_unimarc_flat_field
    'type'        => {'608' => 'it'},

    # type 4: # get_multiple_objects_attributes_from_unimarc_subfields
    'creator'     => [{'700' => {'it' => '$a', 'code' => '$3'}},
                      {'710' => {'it' => '$a', 'code' => '$3'}}],
    'contributor' => [{'701' => {'it' => '$a', 'code' => '$3'}},
                      {'711' => {'it' => '$a', 'code' => '$3'}},
                      {'702' => {'it' => '$a', 'code' => '$3'}}],
    'subject'     => [{'676' => {'it' => '$1', 'code' => '$a'}},
                      {'610' => {'it' => '$a'}}],
    'format'      => [{'336' => {'it' => '$a'}}],
    'publisher'   => [{'210' => {'it' => '$c'}}],
    'language'    => [{'101' => {'code' => '$a'}}],

    # type 5:  # get_flattened_value_from_unimarc_complex_fields
    'unstored'    => ['300']
  }

  class << self
    attr_reader :voghera_unimarc, :chandler, :saffo, :saffo_2, :leopardi, :christie, :biondillo, :enigma
  end

  @christie = <<-UNIMARC
    05382nam0M2200949  I450
    001 IT\\ICCU\\PAR\\0675027
    005 20100610
    010    $a 88-04-52228-3
    100    $a 20031017d2003    |||||itac50      ba
    101 |  $a ita $a eng
    102    $a IT
    200 1  $a HI Icapolavori di Agatha Christie $f introduzione di John G. Cawelti
    210    $a Milano $c Oscar Mondadori $d 2003
    215    $a XXX, 878 p., [4] c. di tav. $c ill. $d 20 cm.
    225 0  $a Grandi classici $v 87
    410  1 $1 001IT\\ICCU\\CFI\\0162160 $1 2001  $a Grandi classici $v 87
    423  1 $1 001IT\\ICCU\\LO1\\0349727 $1 2001  $a Assassinio sull'Orient Express.
    423  1 $1 001IT\\ICCU\\LO1\\0349728 $1 2001  $a HL' Iassassinio di Roger Ackroyd.
    423  1 $1 001IT\\ICCU\\RAV\\0204139 $1 2001  $a Dieci piccoli indiani
    423  1 $1 001IT\\ICCU\\TO0\\1062236 $1 2001  $a Istantanea di un delitto
    676    $a 823.912 $v 21 $1 NARRATIVA INGLESE, 1900-1945
    700  1 $a Christie, Agatha $3 IT\\ICCU\\CFIV\\000252 $4 070
    702  1 $a Cawelti, John G. $3 IT\\ICCU\\MILV\\133716
    801  0 $a IT $b ICCU $c 20100615
    899    $a Biblioteca civica Novi Ligure AL $1 AL0060 $2 TO033
    899    $a Biblioteca civica G. Borsalino Precetto di Valenza AL $1 AL0233 $2 TO0Y4
    899    $a Biblioteca comunale Luciano Benincasa Ancona AN $1 AN0001 $2 ANABA
  UNIMARC

  @voghera_unimarc = <<-UNIMARC
          01262nas0S2200277  I450
    001 IT\\ICCU\\CFI\\0388383
    005 20091211
    100    $a 19980722a19221922|||||itac50      ba
    101 |  $a ita
    102    $a IT
    200 1  $a HIl Igiornale  di  Voghera
    207  1 $a 2. ser, a.3, n.1(mag. 1922)-
    210    $a Voghera $c [s.n.! $d [1922!-
    215    $a v. $c ill. $d 46 cm
    230    $a fantascienza
    135    $a nanoscienza
    300    $a Settimanale
    430  1 $1 001IT\\ICCU\\CFI\\0355942 $1 2001  $a HL' Iidea popolare
    517 0  $a Giornale  di  Voghera  e circondario.
    801  0 $a IT $b ICCU $c 20091213
    899    $a Biblioteca civica Pier Angelo Soldini Castelnuovo Scrivia AL $1 AL0033 $2 TO0KJ
    899    $a Biblioteca civica Tortona AL $1 AL0100 $2 TO032 $4 A.14, n.30(27 lug. 1933)
    899    $a Gruppo biblioteche speciali di Bergamo Bergamo BG $1 BG0367 $2 LO110
    899    $a Biblioteca nazionale centrale Firenze FI $1 FI0098 $2 CFICF $4 3(1922)-57/58(1980);59(1982)-80(2003)- in gran parte lac.
    899    $a Biblioteca nazionale Braidense Milano MI $1 MI0185 $2 MILNB
    899    $a Biblioteca Civica Ricottiana Voghera PV $1 PV0190 $2 LO133
    899    $a Biblioteca universitaria Pavia PV $1 PV0291 $2 MILUP $4 1922-1943;1947- lacunoso
    899    $a Biblioteca nazionale centrale Vittorio Emanuele II Roma RM $1 RM0267 $2 BVECR $4 60(1983)-79(2002)- lac 1983
  UNIMARC

  @chandler = <<-UNIMARC
          01352nam1W2200289  I450
    001 IT\\ICCU\\MOD\\0126858
    005 20010330
    100    $a 20010330d1980    |||||itac01      ba
    101 |  $a ita
    102    $a IT
    200 1  $a 2: (1944-1959) $f Raymond Chandler
    205    $a 4. ed
    210    $a Milano $c A. Mondadori $d 1980
    215    $a 778 p.
    300    $a Contiene: Troppo tardi ; Il lungo addio ; Ancora una notte ; La matita ; Poodle Springs story ; La semplice arte del delitto ; Ancora sul giallo ; Lettere in giallo.
    461  1 $1 001IT\\ICCU\\ANA\\0021957 $1 2001  $a Tutto Marlowe investigatore /  Raymond   Chandler
    608    Libro remainder (field aggiunto da Luca)
    700  1 $a Chandler, Raymond $3 IT\\ICCU\\CFIV\\048542
    801  0 $a IT $b ICCU $c 20040213
    899    $a Biblioteca civica Tortona AL $1 AL0100 $2 TO032
    899    $a Biblioteca provinciale Brindisi BR $1 BR0003 $2 BRI01
  UNIMARC

  @saffo = <<-UNIMARC
            01720ndm112200349  M450
    001 IT\\ICCU\\DM\\99012205938
    005 19990122
    017 02 $a I-Mc . Noseda . Noseda O.38
    100    $a 19990122F18401860|||||itac0103    ba
    101 |  $a ita
    105    $a     A    ||||
    106    $a h
    128  0 $a opera $b S,Mzs,Mzs,T,T,B,B,Coro(S1,S2,T1,T2,B1,B2),ott,fl,ob1,ob2,cl1,cl2,cor1,cor2,cor3,cor4,tr1,tr2,fag1,fag2,trb1,trb2,trb3,serp,banda,arp,timp,gc,vl1,vl2,vla,vlc,b $c 7V,Coro(5V),orch
    200 1  $a Saffo  /  Tragedia   Lirica  in Tre Parti di Sa. Cammarano / Musica del Maestro / Giovanni Pacini / Atto Primo
    208    $a partitura
    210    $g Copia $h 19/m
    215    $a 304 c. $d 390x270 mm
    300    $a DG: 6503. - A c. 1r in alto a destra a pennino: 10,476
    323    $a Alcandro-B
    323    $a Ippia-T
    323    $a Faone-T
    323    $a Saffo-S
    323    $a Lisimaco-B
    323    $a Climene-Mzs
    323    $a Dirce-Mzs
    500    $a Saffo . 1840c . S,Mzs,Mzs,T,T,B,B,Coro(S1,S2,T1,T2,B1,B2),ott,fl,ob1,ob2,cl1,cl2,cor1,cor2,cor3,cor4,tr1,tr2,fag1,fag2,trb1,trb2,trb3,serp,banda,arp,timp,gc,vl1,vl2,vla,vlc,b $h 3 $k 1840c $l opera $r S,Mzs,Mzs,T,T,B,B,Coro(S1,S2,T1,T2,B1,B2),ott,fl,ob1,ob2,cl1,cl2,cor1,cor2,cor3,cor4,tr1,tr2,fag1,fag2,trb1,trb2,trb3,serp,banda,arp,timp,gc,vl1,vl2,vla,vlc,b $3 IT\\ICCU\\CO\\990122061
    700  1 $a Pacini, Giovanni<1796-1867> $3 IT\\ICCU\\NO\\89061301935 $4 230
    899    $a Biblioteca del Conservatorio di musica Giuseppe Verdi Milano MI $1 MI0344 $2 BI43122500012 $c Noseda O.38 $3 Noseda
    920    $2 N $a 304 c. $q 390x270 mm
    922    $n 3
    924    $b Fascicoli non rilegati
    926    $a  I I $c  DIVINI CARMI  $f  2 1 $g  1 1 $h  T1 ob $i  coro ouverture $l  d D $m  C-4 G-2 $n  bB xFC $o  6/8 2/4 $p  And.e s.i.m.
  UNIMARC

  @saffo_2 = <<-UNIMARC
    00806naa2N2200205  M450
    001 IT\\ICCU\\DE\\98102806009
    005 19981028
    100    $a 19981028F0   9999|||||itac0103    ba
    101 |  $a ita
    102    $a IT
    105    $a     Y    ||||
    200 1  $a RUGGERO IN PALESTINA $e Ballo Epico $a cor.: Livio Morosini
    210    $a Genova $c PAGANO F.LLI
    215    $a 1 $d 20 x 12 cm
    463  1 $1 001IT\\ICCU\\DE\\98102805998 $1 2001  $a SAFFO  :  Tragedia   Lirica  / Gio. Pacini ; libretto: Salvadore Cammarano
    620    $d Genova
    702  1 $a Morosini, Livio $3 IT\\ICCU\\NO\\03041801038 $4 200
    712 02 $a Pagano fratelli $3 IT\\ICCU\\NO\\98102801607 $4 650
    899    $a Biblioteche della Fondazione Giorgio Cini Venezia VE $1 VE0239 $2 BI98102700001 $c R PACINI SAFFO $3 ROLANDI
    922    $s GENOVA, CARLO FELICE,  1842
  UNIMARC

  @leopardi = <<-UNIMARC
    01580nam2M2200301  I450
    001 IT\\ICCU\\NAP\\0478279
    005 20100329
    100    $a 20100111d2009    |||||itac50      ba
    101 |  $a ita
    102    $a IT
    200 1  $a H2: IAppendici $f Giacomo Leopardi $g edizione critica diretta da Franco Gavazzeni $g a cura di Cristiano Animosi ... [et al.]
    205    $a Nuova ed
    210    $a Firenze $c presso L'Accademia della Crusca $d 2009
    215    $a 365 p. $d 25 cm
    462  1 $1 001IT\\ICCU\\CFI\\0746764 $1 2001  $a Canti
    700  1 $a Leopardi, Giacomo <1798-1837> $3 IT\\ICCU\\CFIV\\002049 $4 070
    702  1 $a Gavazzeni, Franco $3 IT\\ICCU\\CFIV\\026051
    702  1 $a Animosi ,  Cristiano $3 IT\\ICCU\\LO1V\\306674
    801  0 $a IT $b ICCU $c 20100404
    899    $a Biblioteca nazionale centrale Firenze FI $1 FI0098 $2 CFICF
    899    $a Biblioteca nazionale Braidense Milano MI $1 MI0185 $2 MILNB
  UNIMARC

  @biondillo = <<-UNIMARC



      Scheda dettagliata
      Catalogo SBN
      Ricerca:  Autore = biondillo


      1.LEADER 07791nam0M2201177  I450
      001 IT\\ICCU\\MIL\\0418903
      005 20000113
      010   $a88-86498-73-X
      020   $b2000-1771
      100   $a19990616d1999    |||||itac50      ba
      101 | $aita
      102   $aIT
      200 1 $aGiovanni Michelucci$ebrani di citta aperti a tutti$fGianni Biondillo
      210   $aTorino$cTesto & immagine$d1999
      215   $a93 p.$cill.$d19 cm.
      225 0 $aUniversale di architettura$v57
      312   $aTit. sul dorso
      410  1$1001IT\\ICCU\\REA\\0036400$12001 $aUniversale di architettura$v57
      517 0 $aMichelucci.
      606   $aMichelucci, Giovanni$2FI$3IT\\ICCU\\CFIC\\082201
      676   $a720.92$v21$1ARCHITETTURA. Persone
      700  1$aBiondillo , Gianni$3IT\\ICCU\\RAVV\\102107$4070
      801  0$aIT$bICCU$c20090104
      899   $aBiblioteca civica Giovanni Canna Casale Monferrato AL$1AL0114$2TO049
      899   $aSistema bibliotecario urbano di Vicenza Vicenza VI$1VI0172$2VIASB



  UNIMARC

  @enigma = <<-UNIMARC
    00811nam0M2200181  I450
    001 IT\ICCU\PUV\0639145
    005 20021014
    100    $a 20001218d1956    |||||itac50      ba
    101 |  $a rum
    102    $a RO
    200 1  $a Enigma   otiliei $e roman $f G. Calinescu
    210    $a  $c Ed. de Stat pentru Literatura si Arta $d 1956
    215    $a 486 p. $c ill. $d 20 cm.
    700  1 $a Calinescu, George <1899-1965> $3 IT\ICCU\SBLV\075604 $4 070
    801  0 $a IT $b ICCU $c 20100117
    899    $a Biblioteca comunale Ariostea Ferrara FE $1 FE0017 $2 UFEAR
    899    $a Biblioteca delle facolta' di Giurisprudenza e Lettere e filosofia dell'Universita' degli studi di Milano Milano MI $1 MI0190 $2 USMA6
    899    $a Biblioteca del Centro interdipartimentale di servizi di Palazzo Maldura dell'Universita' degli studi di Padova Padova PD $1 PD0343 $2 PUV21
  UNIMARC





end


  # http://www.iccu.sbn.it/genera.jsp?id=118
  #
  # DUBLIN CORE:  Title
  # BIB1: 1097
  # UNIMARC:  Non qualificato: 200 Titolo
  #           Qualificato:  200 $a Titolo Proprio (Ripetibile)
  #                         200 $c Titolo proprio di altro autore
  #                         200 $e Complemento del titolo
  #                         517 $a Variante del titolo
  #                         500 $a Titolo uniforme
  #                         530 $a Titolo chiave
  #
  # http://www.biblio.uniroma2.it/taginfo.html
  #
  # 200_XX  Titolo e indicazione di responsabilità
  #         Obbligatorio
  #         Non ripetibile
  #         Indicatore nella prima posizione: 0 titolo non significativo
  #                                           1 titolo significativo
  #         Indicatore nella seconda posizione: non definito
  #         Sottocampi:
  #                   $a Titolo proprio (obbligatorio, almeno uno per record, ripetibile)
  #                   $b Designazione materiale (ripetibile)
  #                   $c Titolo proprio di altro autore (ripetibile)
  #                   $d Titolo parallelo (ripetibile)
  #                   $e Complemento del titolo (ripetibile)
  #                   $f Prima formulazione di responsabilità (ripetibile)
  #                   $g Altre formulazioni di responsabilità (ripetibile)
  #                   $h Numero della parte (ripetibile)
  #                   $i Nome della parte (ripetibile)
  #                   $v Indicazione Volume (non ripetibile)
  #                   $z Lingua titolo parallelo (3 caratteri, ripetibile)
  #                   $5 Istituzione di riferimento per il campo (non ripetibile)
  #
  # UNIMARC subfield  |  Element name ISBD (G) Section               |  Preceding punctuation
  #-------------------+----------------------------------------------+------------------------
  # $a                |  Title proper                     1.1        |  New area
  # $a (repeated)     |  Title proper by the same author  1.6        |  ;
  # $b                |  General material designation  1.2           |  [ ]
  # $c                |  Title proper by another author  1.6         |  .
  # $d                |  Parallel title proper  1.3                  |  =
  # $e                |  Other title information  1.4                |  :
  # $f                |  First statement of responsibility  1.5      |  /
  # $g                |  Subsequent statement of responsibility  1.5 |  ;
  # $h                |  Number of a part  1.1.4 ISBD(S)             |  .
  # $i                |  Name of a part  1.1.4 ISBD(S)               |  , if after $h, else .

  # http://www.iccu.sbn.it/genera.jsp?id=118
  #
  # DUBLIN CORE:  Description
  # BIB1: 1100
  # UNIMARC:  Non qualificato: 300 Note generali
  #           Qualificato:  330 $a Sommario o abstract
  #
  # http://www.biblio.uniroma2.it/taginfo.html
  #
  # 215 Descrizione fisica
  # Occorrenza: ripetibile
  # Indicatori: non definiti
  # Codici di sottocampo:
  #   $a Indicazione specifica del materiale ed estensione del documento (ripetibile)
  #   $c Altre particolarità fisiche (non ripetibile)
  #   $d Dimensioni (ripetibile)
  #   $e Materiale allegato (ripetibile)
  #
  # UNIMARC subfield    Element name                                      ISBD (G) Section    Preceding punctuation
  # ---------------------------------------------------------------------------------------------------------------
  # $a                  Specific material designation and extent of item  5.1                 New area
  # $c                  Other physical details                            5.2                 :
  # $d                  Dimensions                                        5.3                 ;
  # $e                  Accompanying materials                            5.4                 +

  # 300 Note generali
  # Occorrenza:ripetibile
  # Indicatore: non definiti
  # Codici sottocampo:
  #   $a Testo di nota (Non ripetibile)
  #
  # 330 Sommario o abstract
  # Occorrenza: ripetibile
  # Indicatori: non definiti
  # Codici di sottocampo:
  #   $a Testo di nota (Non ripetibile)





  # 001_XX  Numero di record
  #         Obbligatorio
  #         Non ripetibile
  #         Nessun indicatore di campo
  #         Nessun indicatore di sottocampo



  # 010_XX  Codice ISBN
  #         Facoltativo
  #         Ripetibile
  #         Indicatori non definiti
  #         Sottocampi: a - Numero
  #                     b - Qualificazione
  #                     d - Disponibilità/prezzo
  #                     z - Numero errato



  # 011_XX  Codice ISSN
  #         Facoltativo
  #         Ripetibile
  #         Indicatori non definiti
  #         Sottocampi: a - Numero
  #                     b - Qualificazione
  #                     d - Disponibilità/prezzo
  #                     z - Numero errato


  # 324_XX  Note di edizione fac-similare
  #         Facoltativo
  #         Non ripetibile
  #         Indicatori non definiti
  #         Sottocampi: a - Testo della nota
  # 324 Nota di edizione originale
  # Occorrenza: non ripetibile
  # Indicatori: non definiti
  # Codici sottocampo:
  # $a Testo di nota (Non ripetibile)


  #  210 Area relativa al materiale specifico: pubblicazione, distribuzione etc.
  #  Occorrenza: ripetibile
  #  Indicatore 1: sequenza di dati sulla pubblicazione
  #      # non applicabile / primo editore disponibile
  #      0 editore subentrante
  #      1 attuale editore / ultimo editore
  #  Indicatore 2: non definito
  #  Codici di sottocampo
  #    $a Luogo di pubblicazione, distribuzione, etc. (ripetibile)
  #    $b Indirizzo dell'editore, distributore, etc. (ripetibile)
  #    $c Nome dell'editore, distributore, etc. (ripetibile)
  #    $d Data di pubblicazione, distribuzione, etc. (ripetibile)
  #    $e Luogo di stampa (ripetibile)
  #    $f Indirizzo dello stampatore (ripetibile)
  #    $g Nome dello stampatore(ripetibile)
  #    $h Data di stampa (ripetibile)
  #  UNIMARC subfield  Element name                                        ISBD (G) Section    Preceding punctuation
  #  ----------------------------------------------------------------------------------------------------------------
  #  $a                Place of publication, distribution, etc             4.1                 New area
  #  $a (repeated)     Subsequent place of publication, distribution etc   4.1                 ;
  #  $b                Address of publisher, distributor, etc              4.2
  #  $c                Name of publisher, distributor, etc                 4.3                 :
  #  $d                Date of publication, distribution, etc              4.4                 ,
  #  $e                Place of manufacture                                4.5                 (if present
  #  $e (repeated)     Subsequent place of manufacture                     4.7
  #  $f                Address of manufacturer
  #  $g                Name of manufacturer                                4.6                 :
  #  $h                Date of manufacture                                 4.7                 ,

  # http://www.iccu.sbn.it/genera.jsp?id=118
  #
  # Guida del record , Posizione 6
  # 135 Dati codificati: Risorse elettroniche
  # 230 Caratteristiche delle Risorse elettroniche
  #
  # http://www.biblio.uniroma2.it/taginfo.html
  #
  # LDR_XX GUIDA
  #  Obbligatorio
  #  Non ripetibile
  #  Nessun indicatore di campo
  #  Nessun indicatore di sottocampo
  #  Le posizioni dei dati sono fisse
  #    |__ 6 Tipo di record: a Materiale a stampa
  #                          b Materiale manoscritto
  #                          c Spartiti musicali a stampa
  #                          d Spartiti musicali manoscritti
  #                          e Materiale cartografico a stampa
  #                          f Materiale cartografico manoscritto
  #                          g Video
  #                          i Audio registrazioni, esecuzioni non musicali
  #                          j Audio registrazioni, esecuzioni musicali
  #                          k Grafica bidimensionale (disegni, dipinti etc.)
  #                          l Computer media
  #                          m Multimedia
  #                          r Opere d'arte tridimensionali
  #
  # 135_XX Dati Codificati Contenuto: Computer files
  #  Facoltativo
  #  Ripetibile
  #  Indicatori non definiti
  #  Sottocampi:
  #  a – Tipo di dati dei files principali
  #
  # 230_XX Caratteristiche dei computer files
  #  Obbligatorio per i computer files
  #  Ripetibile solo quando le caratteristiche del file di più di un file sono descritte in uno singolo record
  #  Indicatori non definiti
  #  Sottocampi: a – Nome ed estenzione del file








  # OPAC: http://www.iccu.sbn.it/genera.jsp?id=118
  #
  # Non qualificato:
  #     610 $a Descrittore di soggetto non controllato
  # Qualificato:
  #     606 Nome topico usato come soggetto
  #     676 DDC
  #     675 UDC
  #     680 LCC
  #     686 Altri sistemi di classificazione
  #
  # http://unimarc-it.wikidot.com/
  #
  # 610 Termini di soggetto non controllati
  # Occorrenza: ripetibile
  # Indicatore 1: livello del termine di soggetto
  #     * 0 nessun livello specificato
  #     * 1 termine primario
  #     * 2 termine secondario
  # Indicatore 2: non definito
  # Codici di sottocampo:
  #     * $a termine di soggetto (ripetibile)
  #
  # 606 Nome comune usato come soggetto
  # Occorrenza: ripetibile
  # Indicatore 1: livello del soggetto
  #     * 0 nessun livello specificato
  #     * 1 termine primario
  #     * 2 termine secondario
  #     * # (non definito) - nessuna informazione disponibile
  # Indicatore 2: non definito
  # Codici di sottocampo:
  #     * $a elemento principale (non ripetibile)
  #     * $j suddivisione formale (ripetibile)
  #     * $x suddivisione generale (ripetibile)
  #     * $y suddivisione geografica (ripetibile)
  #     * $z suddivisione cronologica (ripetibile)
  #     * $2 codice di sistema di soggettazione (non ripetibile)
  #     * $3 numero di registrazione di autorità (non ripetibile)
  #
  # 676 Classificazione Decimale Dewey (CDD)
  # Occorrenza: ripetibile
  # Indicatori: non definiti
  # Codici di sottocampo:
  #     * $a numero (non ripetibile)
  #     * $v edizione (non ripetibile)
  #     * $z lingua dell'edizione (non ripetibile)
  #     * $3 numero di registrazione della classificazione (non ripetibile)

  #
  # 675 Classificazione Decimale Universale (CDU)
  # Occorrenza: ripetibile
  # Indicatori: non definiti
  # Codici di sottocampo:
  #     * $a numero (non ripetibile)
  #     * $v edizione (non ripetibile)
  #     * $z lingua dell'edizione (non ripetibile)
  #     * $3 numero di registrazione della classificazione (non ripetibile)
  #
  # 680 Classificazione della Library of Congress
  # Occorrenza: ripetibile
  # Indicatori: non definiti
  # Codici di sottocampo:
  #     * $a numero della classe (non ripetibile)
  #     * $b numero del libro (non ripetibile)
  #     * $3 numero di registrazione della classificazione (non ripetibile)
  #
  # 686 Altre classificazioni
  # Occorrenza: ripetibile
  # Indicatori: non definiti
  # Codici di sottocampo:
  #     * $a numero della classe (ripetibile)
  #     * $b numero del libro (ripetibile)
  #     * $c suddivisione della classificazione (ripetibile)
  #     * $v edizione (non ripetibile)
  #     * $2 codice di sistema (non ripetibile)
  #     * $3 numero di registrazione della classificazione (non ripetibile)







  # http://www.iccu.sbn.it/genera.jsp?id=118
  #
  # Format
  #   BIB-1: 1107
  #   336 $a Tipo di risorsa elettronica
  #   856 $q Tipo di formato elettronico
  #
  # http://unimarc-it.wikidot.com/336
  #
  # 336 Nota sul tipo di risorsa elettronica
  # Occorrenza: ripetibile
  # Indicatori: non definiti
  # Codici di sottocampo:
  #     * $a Testo di nota (Non ripetibile)
  #
  # http://unimarc-it.wikidot.com/856
  #
  # 856 Localizzazione ed accesso elettronici
  # Occorrenza: ripetibile
  # Indicatore 1: Modalità di accesso
  #     * Nessuna informazione fornita
  #     * Email
  #     * 1 FTP
  #     * 2 Login da remoto (Telnet)
  #     * 3 Dial-up
  #     * 4 HTTP
  #     * 7 Modalità specifica in $y
  # Indicatore 2: non definito
  # Codici di sottocampo:
  #     * $a Nome Host (ripetibile)
  #     (omissis)...

# FORMATS APPARTIENE SOLO A DIGITAL OBJECT PER IL MOMENTO
# QUINDI NON VIENE IMPORTATO

  # http://www.iccu.sbn.it/genera.jsp?id=118
  #
  # Creator
  # BIB-1: 1098
  # Non qualificato:
  #     730 $a Nome-Responsabilità intellettuale $4 Codice di relazione
  # Qualificato:
  #     200 $f Prima indicazione di responsabilità
  #     700 $a –Nome di persona-Responsabilità intellettuale principale $4 Codice di relazione
  #     710 $a Nome di ente – Responsabilità intellettuale principale $4 Codice di relazione
  # o se più di una:
  #     701 $a Nome di persona-Responsabilità intellettuale alternativa $4 Codice di relazione
  #     711 $a Nome di ente-Responsabilità intellettuale alternativa $4 Codice di relazione
  #
  # http://unimarc-it.wikidot.com/700
  #
  # 700 Autore personale - Responsabiltà principale
  # Occorrenza: non ripetibile
  # Indicatore 1: non definito
  # Indicatore 2: forma dell'indicatore nome
  #     * 0 Nome inserito sotto nome o ordine diretto
  #     * 1 Nome inserito sotto cognome (nome di famiglia, patronimico, etc.)
  # Codici di sottocampo:
  #     * $a Elemento principale (Non ripetibile)
  #     * $b Ulteriore elemento del nome (Non ripetibile)
  #     * $c Qualificazione, escluse le date (Ripetibile)
  #     * $d Numeri Romani (Non ripetibile)
  #     * $f Date (Non ripetibile)
  #     * $g Scioglimento delle iniziali del nome (Non ripetibile)
  #     * $p Indirizzo/ente di appartenenza (Non ripetibile)
  #     * $3 Numero di registrazione di autorità (Non ripetibile)
  #     * $4 Codice di funzione (Ripetibile)
  #
  # http://unimarc-it.wikidot.com/710
  #
  # 710 Ente collettivo - responsabilità principale
  # Occorrenza: non ripetibile
  # Indicatore 1: indicatore di congresso
  #     * 0 Nome collettivo
  #     * 1 Congresso
  # Indicatore 2: forma dell'indicatore di nome
  #     * 0 Nome in forma invertita
  #     * 1 Nome inserito sotto posto o giurisdizione
  #     * 2 Nome inserito sotto nome in ordine diretto
  # Codici di sottocampo:
  #     * $a Elemento principale (Non ripetibile)
  #     * $b Suddivisione (Ripetibile)
  #     * $c Aggiunta al nome o qualificazione (Ripetibile)
  #     * $d Numero del congresso e/o numero della parte del congresso (Non ripetibile)
  #     * $e Luogo del congresso (Non ripetibile)
  #     * $f Data del congresso (Non ripetibile)
  #     * $g Elemento del nome invertito (Non ripetibile)
  #     * $h Ulteriore parte del nome invertito (Non invertito)
  #     * $p Ente di appartenenza/indirizzo (Non ripetibile)
  #     * $3 Numero di registrazione di autorità (Non ripetibile)
  #     * $4 Codice di funzione (Ripetibile)
  # PER IL MOMENTO IMPLEMENTATI I CAMPI 700 E 710
  #





  # http://www.iccu.sbn.it/genera.jsp?id=118
  # Contributor
  #   BIB-1: 1106
  #   Non qualificato:
  #       200 $g Successiva indicazione di responsabilità (se il ruolo è conosciuto)
  #   Qualificato:
  #       702 $a Nome di persona-Responsabilità intellettuale secondaria $4 Codice di relazione
  #       712 $a Nome di ente-responsabilità intellettuale secondaria $4 Codice di relazione
  #
  # http://unimarc-it.wikidot.com/702
  #
  # 701 Autore personale - Responsabiltà alternativa
  # Occorrenza: ripetibile
  # Indicatore 1: non definito
  # Indicatore 2: forma dell'indicatore nome
  #     * 0 Nome inserito sotto nome o ordine diretto
  #     * 1 Nome inserito sotto cognome (nome di famiglia, patronimico, etc.)
  # Codici di sottocampo:
  #     * $a Elemento principale (Non ripetibile)
  #     * $b Ulteriore elemento del nome (Non ripetibile)
  #     * $c Qualificazione, escluse le date (Ripetibile)
  #     * $d Numeri Romani (Non ripetibile)
  #     * $f Date (Non ripetibile)
  #     * $g Scioglimento delle iniziali del nome (Non ripetibile)
  #     * $p Indirizzo/ente di appartenenza (Non ripetibile)
  #     * $3 Numero di registrazione di autorità (Non ripetibile)
  #     * $4 Codice di funzione (Ripetibile)
  #
  # http://unimarc-it.wikidot.com/702
  #
  # 702 Autore personale - Responsabiltà secondaria
  # Occorrenza: ripetibile
  # Indicatore 1: non definito
  # Indicatore 2: forma dell'indicatore nome
  #     * 0 Nome inserito sotto nome o ordine diretto
  #     * 1 Nome inserito sotto cognome (nome di famiglia, patronimico, etc.)
  # Codici di sottocampo
  #     * $a Elemento principale (Non ripetibile)
  #     * $b Ulteriore elemento del nome (Non ripetibile)
  #     * $c Qualificazione, escluse le date (Ripetibile)
  #     * $d Numeri Romani (Non ripetibile)
  #     * $f Date (Non ripetibile)
  #     * $g Scioglimento delle iniziali del nome (Non ripetibile)
  #     * $p Indirizzo/ente di appartenenza (Non ripetibile)
  #     * $3 Numero di registrazione di autorità (Non ripetibile)
  #     * $4 Codice di funzione (Ripetibile)
  #     * $5 Istituzione di riferimento per il campo (Non ripetibile) (solo 702)
  #
  # http://unimarc-it.wikidot.com/711
  #
  # 711 Ente collettivo - responsabilità alternativa
  # Occorrenza: ripetibile
  # Indicatore 1: indicatore di congresso
  #     * 0 Nome collettivo
  #     * 1 Congresso
  # Indicatore 2: forma dell'indicatore di nome
  #     * 0 Nome in forma invertita
  #     * 1 Nome inserito sotto posto o giurisdizione
  #     * 2 Nome inserito sotto nome in ordine diretto
  # Codici di sottocampo:
  #     * $a Elemento principale (Non ripetibile)
  #     * $b Suddivisione (Ripetibile)
  #     * $c Aggiunta al nome o qualificazione (Ripetibile)
  #     * $d Numero del congresso e/o numero della parte del congresso (Non ripetibile)
  #     * $e Luogo del congresso (Non ripetibile)
  #     * $f Data del congresso (Non ripetibile)
  #     * $g Elemento del nome invertito (Non ripetibile)
  #     * $h Ulteriore parte del nome invertito (Non invertito)
  #     * $p Ente di appartenenza/indirizzo (Non ripetibile)
  #     * $3 Numero di registrazione di autorità (Non ripetibile)
  #     * $4 Codice di funzione
  #
  # http://unimarc-it.wikidot.com/712
  #
  # 712 Ente collettivo - responsabilità secondaria
  # Occorrenza: ripetibile
  # Indicatore 1: indicatore di congresso
  #     * 0 Nome collettivo
  #     * 1 Congresso
  # Indicatore 2: forma dell'indicatore di nome:
  #     * 0 Nome in forma invertita
  #     * 1 Nome inserito sotto posto o giurisdizione
  #     * 2 Nome inserito sotto nome in ordine diretto
  # Codici di sottocampo:
  #     * $a Elemento principale (Non ripetibile)
  #     * $b Suddivisione (Ripetibile)
  #     * $c Aggiunta al nome o qualificazione (Ripetibile)
  #     * $d Numero del congresso e/o numero della parte del congresso (Non ripetibile)
  #     * $e Luogo del congresso (Non ripetibile)
  #     * $f Data del congresso (Non ripetibile)
  #     * $g Elemento del nome invertito (Non ripetibile)
  #     * $h Ulteriore parte del nome invertito (Non invertito)
  #     * $p Ente di appartenenza/indirizzo (Non ripetibile)
  #     * $3 Numero di registrazione di autorità (Non ripetibile)
  #     * $4 Codice di funzione
  #     * $5 Istituzione e copia di riferimento per il campo (Obbligatorio. Non ripetibile) (solo 712)
  #
  # PER IL MOMENTO IMPLEMENTATI I CAMPI 701, 702 E 711
  #


  # http://www.iccu.sbn.it/genera.jsp?id=118
  #
  # Publisher
  # BIB-1: 1101
  # Non qualificato:
  #     210 $c Nome di editore, distributore, etc.
  # Qualificato:
  #     712$a Nome di ente-Responsabilità secondaria$4Codice di relazione
  #
  # http://unimarc-it.wikidot.com/210
  #
  # 210 Area relativa al materiale specifico: pubblicazione, distribuzione etc.
  # Occorrenza: ripetibile
  # Indicatore 1: sequenza di dati sulla pubblicazione
  #     * # non applicabile / primo editore disponibile
  #     * 0 editore subentrante
  #     * 1 attuale editore / ultimo editore
  # Indicatore 2: non definito
  # Codici di sottocampo
  #     * $a Luogo di pubblicazione, distribuzione, etc. (ripetibile)
  #     * $b Indirizzo dell'editore, distributore, etc. (ripetibile)
  #     * $c Nome dell'editore, distributore, etc. (ripetibile)
  #     * $d Data di pubblicazione, distribuzione, etc. (ripetibile)
  #     * $e Luogo di stampa (ripetibile)
  #     * $f Indirizzo dello stampatore (ripetibile)
  #     * $g Nome dello stampatore(ripetibile)
  #     * $h Data di stampa (ripetibile)
  #
  # http://unimarc-it.wikidot.com/712
  #
  # 712 Ente collettivo - responsabilità secondaria
  # Occorrenza: ripetibile
  # Indicatore 1: indicatore di congresso
  #     * 0 Nome collettivo
  #     * 1 Congresso
  # Indicatore 2: forma dell'indicatore di nome:
  #     * 0 Nome in forma invertita
  #     * 1 Nome inserito sotto posto o giurisdizione
  #     * 2 Nome inserito sotto nome in ordine diretto
  # Codici di sottocampo:
  #     * $a Elemento principale (Non ripetibile)
  #     * $b Suddivisione (Ripetibile)
  #     * $c Aggiunta al nome o qualificazione (Ripetibile)
  #     * $d Numero del congresso e/o numero della parte del congresso (Non ripetibile)
  #     * $e Luogo del congresso (Non ripetibile)
  #     * $f Data del congresso (Non ripetibile)
  #     * $g Elemento del nome invertito (Non ripetibile)
  #     * $h Ulteriore parte del nome invertito (Non invertito)
  #     * $p Ente di appartenenza/indirizzo (Non ripetibile)
  #     * $3 Numero di registrazione di autorità (Non ripetibile)
  #     * $4 Codice di funzione
  #     * $5 Istituzione e copia di riferimento per il campo (Obbligatorio. Non ripetibile) (solo 712)
  #
  # PER IL MOMENTO IMPLEMENTATO IL CAMPO 210
  #




  # language list: http://www.loc.gov/marc/languages/language_code.html
  #
  # 101_XX  Lingua della pubblicazione
  #         Obbligatorio se l'opera ha una lingua
  #         Non ripetibile
  #         Il codice DEVE essere quello associato alla lingua come riportato in: http://lcweb.loc.gov/marc/languages/
  #         Indicatore nella prima posizione: traduzione: 0 Lingua originale
  #                                                       1 Traduzione dall’originale o in lavoro intermedio
  #                                                       2 Contiene traduzioni other than translated summaries
  #         Indicatore nella seconda posizione: non definito
  #         Sottocampi: a - Lingua del testo
  #                     b - Lingua del testo intermedio
  #                     c - Lingua del testo originale
  #                     d - Lingua del compendio
  #                     e - Lingua degli indici
  #                     f - Lingua del frontespizio
  #                     g - Lingua del titolo proprio
  #                     h - Lingua del libretto, ecc.
  #                     i - Lingua del materiale allegato
  #                     j - Lingua dei sottotitoli


  # http://www.iccu.sbn.it/genera.jsp?id=240
  # http://unimarc-it.wikidot.com/210
  #
  # 300 Note generali
  # Occorrenza:ripetibile
  # Indicatore: non definiti
  # Codici sottocampo:
  #     * $ a Testo di nota (Non ripetibile)


  # esempio di hash dopo il parsing
  #[["001", ["ICCU\\LO1\\1103972"]],
  # ["005", ["70205"]],
  # ["010", [{"$a"=>"9788804307679"}]],
  # ["100", [{"$a"=>"20070205d2007 |||||itac50 ba"}]],
  # ["101", [{:indicator_1=>"|", "$a"=>"ita"}]],
  # ["102", [{"$a"=>"IT"}]],
  # ["200", [{"$f"=>"Agatha Christie", "$g"=>"traduzione di Beata Della Frattina", :indicator_1=>"1", "$a"=>"Dieci piccoli indiani"}]],
  # ["205", [{"$a"=>"25. rist"}]],
  # ["210", [{"$d"=>"2007", "$a"=>"Milano", "$c"=>"Mondadori"}]],
  # ["215", [{"$d"=>"20 cm.", "$a"=>"XVI, 209 p."}]],
  # ["225", [{:indicator_1=>"0", "$v"=>"2", "$a"=>"Oscar classici moderni"}]],
  # ["410", [{"$1"=>"001IT\\ICCU\\CFI\\0130259, 2001", "$v"=>"2", "$a"=>"Oscar classici moderni", :indicator_2=>"1"}]],
  # ["500", [{"$3"=>"IT\\ICCU\\CFI\\0097516", "$a"=>"Ten little niggers."}]],
  # ["676", [{"$1"=>"NARRATIVA INGLESE, 1900-1945", "$v"=>"21", "$a"=>"823.912"}]],
  # ["700", [{"$3"=>"IT\\ICCU\\CFIV\\000252", "$4"=>"070", "$a"=>"Christie , Agatha", :indicator_2=>"1"}]],
  # ["702", [{"$3"=>"IT\\ICCU\\CFIV\\022071", "$a"=>"Della Frattina, Beata", :indicator_2=>"1"}]],
  # ["801", [{"$a"=>"IT", "$b"=>"ICCU", :indicator_2=>"0", "$c"=>"20091025"}]],
  # ["899", [{"$1"=>"BG0366", "$2"=>"LO104", "$a"=>"Sistema bibliotecario urbano di Bergamo Bergamo BG"}]]]

