require 'nokogiri'

class TranslationMemory
  
  def initialize(file)
    @doc = Nokogiri::XML(File.open(file))
  end
  
  def version
    @version ||= @doc.xpath("//tmx/@version").text
  end
  
  def properties
    @properties ||= @doc.xpath("//header/prop").inject({}) {|acc,p| acc.merge!( {p["type"].split(":")[0].gsub("x-","") =>  p.text} ) }
  end
  
  def translation_units
    @translation_units ||= @doc.xpath("//body/tu")
  end
  
  def source_language
    @source_language ||= @doc.xpath("//header/@srclang").text
  end
  
  def target_languages
    @target_languages ||= @doc.xpath("//tuv").collect {|t| t.attributes["lang"].value }.uniq - [source_language]
  end
  
end