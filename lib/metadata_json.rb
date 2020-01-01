require 'rubygems'
require 'nokogiri'
require 'json'
require 'faraday'
require 'iso-639'
require 'date'
require 'digest'


class MetadataJson
  #those hashes are used to lookup book category according to LCC or DDC classification. Now only used for ACO books
  @ddc_hash=nil 
  @ddc_ranges_hash=nil 
  @lcc_cat_en=nil 
  @lcc_cat_ar=nil
 
  def get_title(mods_doc, script)
    xpath="/mods/titleInfo[not(@type=\"uniform\") "
    if (script!="Latn")
      xpath +=" and @script=\"#{script}\"" unless script.nil?
    else
      xpath += " and (not(@script)"
      xpath += " or  @script=\"#{script}\"" unless script.nil?
      xpath += ")"
    end
    xpath += "]"
    title = mods_doc.xpath("#{xpath}/nonSort/text()").to_s || ""
    title += " " if !title.nil? && title !~ /\s+$/
    title += mods_doc.xpath("#{xpath}/title/text()").first.to_s

  end

  def get_subtitle(mods_doc, script)
    xpath = "//titleInfo["
    if (script!="Latn")
      xpath +=" @script=\"#{script}\"" unless script.nil?
    else
      xpath += " (not(@script)"
      xpath += " or  @script=\"#{script}\"" unless script.nil?
      xpath += ")"
    end
    xpath += "]/subTitle"
    mods_doc.xpath("#{xpath}/text()").to_s
  end

  def get_authors(mods_doc, script)
    @authors = []
    xpath = "//mods/name[@type='personal'"
    if (script!="Latn")
      xpath +=" and @script=\"#{script}\"" unless script.nil?
    else
      xpath += " and (not(@script)"
      xpath += " or  @script=\"#{script}\"" unless script.nil?
      xpath += ")"
    end
    xpath += "]"
    @names = mods_doc.xpath(xpath)
    @names.each do |node|
      name_parts=node.xpath('./namePart[not(@type="date")]/text()').to_s.strip
      date=node.xpath('./namePart[@type="date"]/text()').to_s.strip
      role=node.xpath('./role/roleTerm[@type="text"]/text()').to_s.strip
      author=[name_parts, date, role].reject(&:empty?).join(', ')
      puts "author: #{author}"
      @authors<<author
    end
    puts "#{@authors}.to_s"
    return @authors
  end

  def get_publisher(mods_doc, script)
    xpath = "//originInfo["
    if (script!='Latn')
      xpath +="@script=\"#{script}\"" unless script.nil?
    else
      xpath += " not(@script) or  @script=\"#{script}\""
    end
    xpath += "]/publisher"
    mods_doc.xpath("#{xpath}/text()").first
  end

  def get_call_number(mods_doc, scripti,marc_file_mapping,marc_file_path,book_id)
    xpath="//classification[\@authority='lcc']"
    call_number=mods_doc.xpath("#{xpath}/text()").to_s
    puts "call number #{call_number}"
    if(call_number.empty?&&marc_file_mapping!=nil)
      call_number=get_call_number_from_marc(marc_file_mapping,marc_file_path,book_id)
    end 
   puts "call number #{call_number}"
   return call_number 
  end

  def get_call_number_from_marc(marc_file_mapping,marc_file_path,book_id)
     f = File.open(marc_file_mapping, "r")
     call_number=""
     f.each_line do |line|
       marc_files=line.split(" ")
       if(marc_files.include?(book_id))
         marc_file_full_path=marc_file_path+"/NjP_"+marc_files[0]+"_marcxml.xml"
         puts marc_file_full_path
         if(File.exist?(marc_file_full_path))
           marc_xml = Nokogiri::XML.parse(File.open(marc_file_full_path)).remove_namespaces! 
           xpath="//datafield[\@tag='852']/subfield[\@code="
           call_numbe=marc_xml.xpath("#{xpath}'h']/text()")+marc_xml.xpath("#{xpath}'i']/text()")
         else
          puts "Marc file is missing" 
         end
       end
     end
     f.close
     return call_number
  end

  def get_description(mods_doc, script)
    xpath="//abstract1"
    mods_doc.xpath("#{xpath}/text()").to_s
  end

  def get_language(mods_doc)
    code=get_language_code(mods_doc)
    puts code
    if(code.nil?)
      return ISO_639.find_by_code("eng").english_name
    else
      ISO_639.find_by_code("#{code}").english_name
    end
  end

  def get_language_code(mods_doc)
    xpath="//language/languageTerm[@authority='iso639-2b' and @type='code']/text()"
    mods_doc.xpath("#{xpath}").first
  end

  def get_number(mods_doc)
    xpath="//physicalDescription/extent"
    physDesc=mods_doc.xpath("#{xpath}/text()").to_s
  end

  def get_subject(mods_doc, script)
    subjects=[]

    xpath = "//subject[@script='#{script}' "
    xpath += "or not(@script)" if script=="Latn"
    xpath += "]"

    mods_doc.xpath(xpath).each do |node|
        subject=get_leaf_vals(node,[])
        puts "subj: #{subject}"
        subjects<<subject.join(' -- ') unless subject.empty?||subject.size==0||subject==""
    end

    return subjects.uniq
    end

    def get_leaf_vals (subj_element,values)
    children = subj_element.elements
    if (!children.empty?)
          children.each do |child |
              if (child.name!="geographicCode")
                    get_leaf_vals(child,values)
              end
          end
     else
       val = subj_element.text()
       values<<val unless val==""||val.nil?
    end
    return values
   end

  def get_publication_location(mods_doc, script)
    xpath = "//originInfo["
    if (script!="Latn")
      xpath +=" @script=\"#{script}\"" unless script.nil?
    else
      xpath += " (not(@script)"
      xpath += " or  @script=\"#{script}\"" unless script.nil?
      xpath += ")"
    end
    xpath += "]/place/placeTerm[\@type='text']"
    mods_doc.xpath("#{xpath}/text()").to_s
  end

  def get_pub_date_string(mods_doc)
    xpath = "//originInfo[ (not(@script) or @script=\"Latn\" )"
    xpath +="]/dateIssued[not(@encoding='marc')]"
    date =mods_doc.xpath("#{xpath}/text()")
    return "" if date.nil?
    date_text=date.to_s.gsub("u", "0")
    date_text=date_text.gsub("&lt;", "")
    date_text=date_text.gsub("&gt;", "")
    puts "text date: #{date} "
    return date_text
    end

  def get_pub_date(date, mods_doc)
     return "" if (date=="")
     return DateTime.parse("#{date.to_s[0,4]}-01-01").strftime("%C%y-%m-%dT%H:%M:%S") if(Date.new(date.to_s[0,4].to_i)).gregorian?
     xpath = "//originInfo[(not(@script) or  @script=\"Latn\")"
     xpath +="]/dateIssued[(@encoding='marc')]"
     date_marc =mods_doc.xpath("#{xpath}/text()")
     if(!date_marc.nil?)
     date_marc_fin=date_marc.to_s[0,4].gsub('u','0')
     return DateTime.parse("#{date_marc_fin}-01-01").strftime("%C%y-%m-%dT%H:%M:%S") if(Date.new(date_marc_fin.to_i)).gregorian?
     end
     xpath = "//originInfo[(not(@script) or  @script=\"Latn\")"
     xpath +="]/dateIssued[point='start']"
      date_marc_start =mods_doc.xpath("#{xpath}/text()")
     if(!date_marc_start.nil?)
     date_marc_fin=date_marc.to_s[0,4].gsub('u','0')
     return DateTime.parse("#{date_marc_fin}-01-01").strftimer("%C%y-%m-%dT%H:%M:%S") if(Date.new(date_marc_fin.to_i)).gregorian?
     end
     date_ajust_first=date.sub(/.*?\[/, '')
     date_ajust=date_ajust_first.gsub(/[^0-9]/i, '')
     date_final=date_ajust.ljust(4,'0')
     puts "final date: #{date_final}"
     return DateTime.parse("#{date_final}-01-01").strftime("%C%y-%m-%dT%H:%M:%S") if (Date.new(date_ajust.to_i)).gregorian?
     return ""
  end

  def get_topic(mods_doc, script,need_category,marc_file_mapping,marc_file_path,book_id)
    topic=""
    if(need_category)
        if(@ddc_hash.nil?)
          @ddc_hash=eval(File.read("category_hashes/ddc_hash"))
        end
        if(@ddc_ranges_hash.nil?)
          @ddc_ranges_hash=eval(File.read("category_hashes/ddc_range"))
        end
        if(@lcc_cat_en.nil?)
          @lcc_cat_en=eval(File.read("category_hashes/lcc_cat_en"))
        end
        if(@lcc_cat_ar.nil?)
          @lcc_cat_ar=eval(File.read("category_hashes/lcc_cat_ar"))
        end
        xpath="//classification[\@authority='lcc']"
        call_number=mods_doc.xpath("#{xpath}/text()").to_s
        puts "call number lcc #{call_number}"
        if(call_number.nil?||call_number.empty?)
          call_number=get_call_number_from_marc(marc_file_mapping,marc_file_path,book_id)
        end
        puts "call number lcc #{call_number}"
        if(!call_number.nil?&&!call_number.empty?)
          topic=topic_lcc_lookup(call_number, script)
        else
          xpath="//classification[\@authority='ddc']"
          call_number=mods_doc.xpath("#{xpath}/text()").to_s
          puts "call number ddc #{call_number}"
          if(!call_number.nil?&&!call_number.empty?)
            topic=get_topic_from_ddc(call_number, script)
          end
       end
     end
    return topic 
  end
  
  def get_topic_from_ddc(call_number, script)
    puts call_number
    topic=""
    first_letter=@ddc_hash[call_number]
    if(!first_letter.nil?&&!first_letter.empty?)
        return topic_lcc_lookup(first_letter,script)
    else 
       @ddc_ranges_hash.each do |first_letter,ddc_ranges|
         ddc_ranges.each do |ddc_range|
           if(ddc_range.include?(call_number))
              return topic_lcc_lookup(first_letter,script)
           end
         end
       end 
    end
    return topic
  end
 
  def topic_lcc_lookup(first_letter, script)
     topic=""
     if(script=='Latn')
        topic=@lcc_cat_en[first_letter] 
     else 
        topic=@lcc_cat_ar[first_letter] 
     end
     return topic
  end

     def get_multivolume(id, volume, volume_str, collection_id, partner_id, script, multi_vol, rstar_username, rstar_password)
       if (script=="Latn"&&multi_vol)
         [
             {
                 :identifier => "#{id}",
                 :volume_number => "#{volume}",
                 :volume_number_str => "#{volume_str}",
                 :collection => [get_collection(collection_id, partner_id, rstar_username, rstar_password)],
                 :isPartOf => [
                     {
                         :title => "Multi-Volume #{id}",
                         :type => "dlts_multivol",
                         :language => "und",
                         :identifier => "#{id}",
                         :ri => nil
                     }
                 ]
             }
         ]
       else
         return ""
       end
     end

     def generate_single_pages(parser, book_id)
       single_pages=[]
       map=parser.for_tag(:div).with_attributes({:TYPE => "INTELLECTUAL_ENTITY"}).first
       map['div'].each do |page|
         label=page.attributes["ID"].gsub('s-', '')
         order=page.attributes["ORDER"].to_i
         page= {:isPartOf => book_id, :sequence => [order], :realPageNumber => order,
                :cm => {:uri => "fileserver://books/#{book_id}/#{label}_d.jp2", :width => "", :height => "", :levels => "",
                        :dwtLevels => "", :compositingLayerCount => "", :timestamp => Time.now().to_i.to_s}}
         single_pages<<page
       end
       return single_pages
     end

     def generate_double_pages(number_of_pages, book_id)
       double_pages=[]
       i=0
       while (i < number_of_pages) do
         is_cover_or_back= (i==0||i==number_of_pages-1) ? :true : false

         left_img_num = i + 1
         right_img_num =i
         if (is_cover_or_back)
           right_img_num = (i + 1)
           i+=1
         else
           right_img_num = i + 2
           i += 2
         end
         stitch_index = "#{left_img_num}-#{right_img_num}"

         left_page_num = left_img_num
         right_page_num = right_img_num

         stitch_file ="#{book_id}_2up_#{left_img_num.to_s.rjust(4, '0')}_#{right_img_num.to_s.rjust(4, '0')}"

         page= {:isPartOf => book_id, :sequence => [left_img_num, right_img_num], :realPageNumber => [left_img_num, right_img_num],
                :cm => {:uri => "fileserver://books/#{book_id}/#{stitch_file}.jp2", :width => "", :height => "", :levels => "",
                        :dwtLevels => "", :compositingLayerCount => "", :timestamp => Time.now().to_i.to_s}}
         double_pages<<page
       end
       return double_pages
     end

     def get_series(mods_doc, collection_id, partner_id, book_id, script, rstart_username, rstar_password)
       if (script=="Latn")
         xpath="//relatedItem[@type='series']/titleInfo[@script='#{script}' "
         xpath+=" or not(@script) " if script=="Latn"
         xpath+="]/title/text()"
         titles = mods_doc.xpath(xpath)
         serieses_str=[]
         titles.each do |title|
           title.to_s.gsub!(/no\./,";no.")
           title.to_s.gsub!(/n\./,";n.")
           title.to_s.gsub!(/v\./,";v.")
           serieses_str<<title.to_s.split(";")
         end
         serieses=[]
         serieses_str.each do |series|
           series_id=Digest::MD5.hexdigest(series[0])
           if(!series[1].nil?)
            volume_number=series[1].to_s.gsub(/[no?\.|v\.]/,'').gsub(/\s+/,"") if Float(series[1].gsub(/\s+/,"")) rescue false
           end
           data= {
               :identifier => "series_#{book_id}_#{series_id}",
               :type => 'dlts_series_book',
               :title => series[0],
               :volume_number => "#{volume_number}",
               :volume_number_str =>"#{series[1]}",
               :collection => [get_collection(collection_id, partner_id, rstart_username, rstar_password)[0]],
               :isPartOf => [
                   {
                       :title => series[0],
                       :type => "dlts_series",
                       :language => "und",
                       :identifier => "series_#{series_id}",
                       :ri => nil
                   }
               ]
           }
           serieses<<data
         end
         return serieses
       else
         return ""
       end
     end

     def get_collection(ids, partner_id, rstar_username, rstar_password)
       cols=[]
       puts partner_id
       @conn = Faraday.new(:url => 'https://rsbe.dlib.nyu.edu')
       @conn.basic_auth(rstar_username, rstar_password)
       ids.each do |id|
         puts "api/v0/colls/#{id}"
         response=@conn.get "api/v0/colls/#{id}"
         col=JSON.parse(response.body).to_hash
         cols<<{
                    :title => "#{col["name"]}",
                    :type => "dlts_collection",
                    :language => "und",
                    :identifier => "#{id.chomp}",
                    :code => "#{col["code"]}",
                    :name => "#{col["name"]}",
                    :partner => get_partner(partner_id, rstar_username, rstar_password)[0]
                }
       end
       return cols
     end

     def get_partner(partner_id, rstar_username, rstar_password)
       @conn = Faraday.new(:url => 'https://rsbe.dlib.nyu.edu')
       @conn.basic_auth(rstar_username, rstar_password)
       response=@conn.get "api/v0/partners/#{partner_id}"
       partner=JSON.parse(response.body).to_hash

       if partner.has_key?("error")
         response=@conn.get "api/v0/providers/#{partner_id}"
         partner=JSON.parse(response.body).to_hash
       end
       [{
            :title => "#{partner["name"]}",
            :type => "dlts_partner",
            :language => "und",
            :identifier => "#{partner_id.chomp}",
            :code => "#{partner["code"]}",
            :name => "#{partner["name"]}"
        }]

     end

end
