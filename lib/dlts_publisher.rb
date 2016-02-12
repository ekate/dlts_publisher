require 'dlts_publisher/version'
require 'rubygems'
require 'nokogiri'
require 'json'
require 'saxerator'
require 'optparse'
require_relative '../lib/metadata_json.rb'
require_relative '../lib/drupal_json.rb'

module DltsPublisher

  @collection_path=ARGV[0]

  @script=ARGV[1]

  @rstar_username=ARGV[2]

  @rstar_password=ARGV[3]

  @json_dir=ARGV[4]||"/home/dlib/ekatep/dlts_viewer_content/books/"

  if (ARGV.size<4)
    puts "You must provide collection_path, script(Latin, Arabic, etc), rstar credentials"
    exit
  end

  @collection_id=[]

  options = {}

  OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"

    opts.on('-d', '--start_date Date', 'Start Date') { |v| options[:start_date] = v }
    opts.on('-c', '--collection_id Collection Id', 'Collection id') { |v| options[:collection_id] = v }
    opts.on('-p', '--partner_id Partner Id', 'Partner id') { |v| options[:partner_id] = v }

  end.parse!


  if !Dir.exist?(@collection_path)
    puts "The collection #{@collection_path} doesn't exist"
    exit
  end

  @collection_file_path="#{@collection_path}/collection_url"

  if !File.exist?(@collection_file_path)
    puts "The file #{@collection_file} for the collection #{@Collection_path} doesn't exist"
    exit
  end

  col_file=File.open(@collection_file_path)

  @collection_id<<col_file.readline.split('/')[-1]

  @collection_id<< options[:collection_id] unless options[:collection_id]==nil

  partner_id=nil

  if(options[:partner_id]!=nil)
    @partner_id=options[:partner_id]
  else
    @partner_file_path="#{File.expand_path("..", @collection_path)}/partner_url"

    if !File.exist?(@partner_file_path)
      puts "The file #{@partner_file_path} for the collection #{@Collection_path} doesn't exist"
      exit
    end

    partner_file=File.open(@partner_file_path)
    @partner_id=partner_file.readline.split('/')[-1]

  end

  if @partner_id==nil
    puts "The @partner for the collection #{@Collection_path} isn't define. Create partner url file or add it as a parameter -p [partner_id]"
    exit
  end



  Dir["#{@collection_path}/wip/ie/**/data/*.xml"].each do |f|
       if(options[:start_date]!=nil)
         mtime = File.mtime(file)
       end
       if(mtime==nil||mtime>Time.now-mtime)


         parser =Saxerator.parser(File.new(f))

         @id=parser.for_tag(:mets).first.attributes["OBJID"]

         @books=[]

         puts "ie id:#{@ie_id}"
         parser.for_tag(:div).with_attributes({:TYPE => "INTELLECTUAL_ENTITY"}).each do |ie|
           if (!ie.nil?)
             book_id=ie['mptr'].attributes["xlink:href"].split("/")[4]
             volume=ie.attributes["ORDERLABEL"]
             volume_order=ie.attributes["ORDER"]
             @books<<[book_id,volume,volume_order]
           end
         end
         @multi_volume=false
         if @books.size>1
           @multi_volume=true
         end


         @books.each do |book|

           puts "books size #{@books.size}"
           puts "books multi #{@multi_volume}"

           @book_id=book[0]

           @handle_file="#{@collection_path}/wip/se/#{@book_id}/handle"

           if !File.exist?(@handle_file)
             puts "The file #{@handle_file} for the book #{@book_id} doesn't exist"
             exit
           end

           file=File.open(@handle_file)

           @handle=file.readline

           @mets_file="#{@collection_path}/wip/se/#{@book_id}/data/#{@book_id}_mets.xml"

           if !File.exist?(@mets_file)
             puts "The file #{@mets_file} for the book #{@book_id} doesn't exist"
             exit
           end

           @doc = Nokogiri::XML.parse(File.open(@mets_file)).remove_namespaces!

           @mets_parser= Saxerator.parser(File.new(@mets_file))

           @mods_file_name=@doc.xpath('//mdRef[@MDTYPE="MODS"]/@href').to_s

           @rights_file_name=@doc.xpath('//mdRef[@MDTYPE="METSRIGHTS"]/@href').to_s

           @rights_file="#{@collection_path}/wip/se/#{@book_id}/data/#{@rights_file_name}"

           if !File.exist?(@rights_file)
             puts "The file #{@rights_file} for the book #{@book_id} doesn't exist"
             exit
           end

           @rights_doc_xml = Nokogiri::XML.parse(File.open(@rights_file)).remove_namespaces!

           @rights=@rights_doc_xml.xpath("//RightsDeclaration/text()").to_s

           @scan_data=@doc.xpath('//structMap/@TYPE').to_s

           @orientation =
               @scan_data.split(' ')[1].split(':')[1] =~ /^horizontal$/i ? 1 : 0
           @read_order =
               @scan_data.split(' ')[2].split(':')[1]=~ /^right(2|_to_)left$/i ? 1 : 0
           @scan_order =
               @scan_data.split(' ')[3].split(':')[1] =~ /^right(2|_to_)left$/i ? 1 : 0

           puts @orientation
           puts @read_order
           puts @scan_order

           @page_count=@doc.xpath('//structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]/div').size

           puts @page_count

           @rep_image_div=@doc.xpath('//structMap/div/div[@TYPE="INTELLECTUAL_ENTITY"]/div').first

           puts @rep_image_div
           label=@rep_image_div.xpath('@ID').to_s.gsub('s-', '')

           puts label

           @rep_image= { :isPartOf => @book_id, :sequence => [1], :realPageNumber => 1,
                         :cm => {:uri => "fileserver://books/#{@book_id}/#{label}_d.jp2", :width=>"", :height=>"", :levels=>"",
                                 :dwtLevels=>"", :compositingLayerCount=>"", :timestamp => Time.now().to_i.to_s}}


           puts @rep_image
           @mods_file="#{@collection_path}/wip/se/#{@book_id}/data/#{@mods_file_name}"

           if !File.exist?(@mods_file)
             puts "The file #{@mods_file} for the book #{@book_id} doesn't exist"
             exit
           end

           @mods_doc_xml = Nokogiri::XML.parse(File.open(@mods_file)).remove_namespaces!

           @mods_doc=MetadataJson.new
           @drupal_doc=DrupalJson.new
           @entity_language="en"
           if(@script=="Arab")
             @entity_language="ar"
           end

           @pub_date_string=@mods_doc.get_pub_date_string(@mods_doc_xml)
           book_data={ :entity_title=>@mods_doc.get_title(@mods_doc_xml, @script),
                       :identifier=>"#{@book_id}",
                       :entity_language=>@entity_language,
                       :entity_status=>"1",
                       :entity_type=>"dlts_book",
                       :metadata=> { :title=>@drupal_doc.drupal_field("Title",@mods_doc.get_title(@mods_doc_xml, @script),"text_textfield","field_title"),
                                     :subtitle=>@drupal_doc.drupal_field("Subtitle",@mods_doc.get_subtitle(@mods_doc_xml, @script),"text_textfield","field_subtitle"),
                                     :author=>@drupal_doc.drupal_field_array("Author/Contributor",@mods_doc.get_authors(@mods_doc_xml, @script), "text_textfield","field_author"),
                                     :publisher=>@drupal_doc.drupal_field("Publisher",@mods_doc.get_publisher(@mods_doc_xml, @script), "text_textfield","field_publisher"),
                                     :publication_location=>@drupal_doc.drupal_field("Place of Publication",@mods_doc.get_publication_location(@mods_doc_xml, @script), "text_textfield","field_publication_location"),
                                     :publication_date_text=>@drupal_doc.drupal_field("Date of Publication",@pub_date_string, "date_text","field_publication_date_text"),
                                     :publication_date=>@drupal_doc.drupal_field("Date of Publication",@mods_doc.get_pub_date(@pub_date_string,@mods_doc_xml), "date_text","field_publication_date"),
                                     :collection=>@drupal_doc.drupal_field_array("Collection",@mods_doc.get_collection(@collection_id,@partner_id,@rstar_username, @rstar_password),"node_reference_autocomplete","field_collection"),
                                     :partner=>@drupal_doc.drupal_field_array("Partner",@mods_doc.get_partner(@partner_id,@rstar_username, @rstar_password),"node_reference_autocomplete","field_partner"),
                                     :handle=>@drupal_doc.drupal_field("Permanent Link","http://hdl.handle.net/#{@handle}","link_field","field_handle"),
                                     :read_order=>@drupal_doc.drupal_field("Read Order",@read_order,"options_buttons","field_read_order"),
                                     :scan_order=>@drupal_doc.drupal_field("Scan Order",@scan_order,"options_buttons","field_read_order"),
                                     :binding_orientation=>@drupal_doc.drupal_field("Binding Orientation",@orientation,"options_buttons","field_read_order"),
                                     :page_count=>@drupal_doc.drupal_field("Read Order",@page_count,"number","field_page_count"),
                                     :sequence_count=>@drupal_doc.drupal_field("Read Order",@page_count,"number","field_sequence_count"),
                                     :call_number=>@drupal_doc.drupal_field("Call Number",@mods_doc.get_call_number(@mods_doc_xml, @script),"text_textfield","field_call_number"),
                                     :description=>@drupal_doc.drupal_field("Description",@mods_doc.get_description(@mods_doc_xml, @script),"text_textfield","field_description"),
                                     :identifier=>@drupal_doc.drupal_field("Identifier",@book_id,"text_textfield","field_identifier"),
                                     :language=>@drupal_doc.drupal_field("Language",@mods_doc.get_language(@mods_doc_xml),"text_textfield","field_language"),
                                     :language_code=>@drupal_doc.drupal_field("Language",@mods_doc.get_language_code(@mods_doc_xml),"text_textfield","field_language_code"),
                                     :number=>@drupal_doc.drupal_field("Number",@mods_doc.get_number(@mods_doc_xml),"text_textfield","field_number"),
                                     :pdf_file=>@drupal_doc.drupal_field_array("PDF",["fileserver://books/#{@book_id}/#{@book_id}_hi.pdf","fileserver://books/#{@book_id}/#{@book_id}_lo.pdf" ],"file_generic","field_pdf_filer"),
                                     :representative_image=>@rep_image,
                                     :rights=>@drupal_doc.drupal_field("Rights",@rights,"text_textarea","field_rights"),
                                     :subject=>@drupal_doc.drupal_field_array("Subject",@mods_doc.get_subject(@mods_doc_xml, @script),"taxonomy_autocomplete","field_subject"),
                       },
                       :multivolume => {:volume=>@mods_doc.get_multivolume(@id,book[2],book[1],@collection_id,@partner_id,@script,@multi_volume,@rstar_username,@rstar_password)},
                       :series=>@mods_doc.get_series(@mods_doc_xml,@collection_id,@partner_id,@book_id,@script,@rstar_username,@rstar_password),
                       :pages=>{:page=>@mods_doc.generate_single_pages(@mets_parser,@book_id)},
                       :stitched=>{:page=>@mods_doc.generate_double_pages(@page_count,@book_id)}}

           fJson = File.open("#{@json_dir}/#{@book_id}.#{@entity_language}.json","w")
           fJson.write(book_data.to_json)
           fJson.close
           puts book_data.to_json
       end
       end
     end
end


