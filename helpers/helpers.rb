module Helpers
  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    str = ""
    1.upto(len) { |i| str << chars[rand(chars.size-1)] }
    return str
  end
  
  def render_attribute_generic(v)
    capture_haml do
      haml_tag :ul do
        haml_tag :li, "Created: #{v[:creationdate]}"
        haml_tag :li, "Changed: #{v[:changedate]}"
        haml_tag :li, "Last Used: #{v[:lastusagedate]}"
      end
    end
  end
  
end