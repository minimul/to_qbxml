class ToQbxml
  #attr_reader :hash, :options

  ACRONYMS = [/Ap\z/, /Ar/, /Cogs/, /Com\z/, /Uom/, /Qbxml/, /Ui/, /Avs/, /Id\z/,
              /Pin/, /Ssn/, /Clsid/, /Fob/, /Ein/, /Uom/, /Po\z/, /Pin/, /Qb/]
  ATTR_ROOT    = 'xml_attributes'.freeze
  IGNORED_KEYS = [ATTR_ROOT]
  ON_ERROR = 'stopOnError'
  REPEATABLE_KEY = 'Repeat' 

  def initialize(hash, options = {})
    @hash = hash
    @options = options
  end

  def make(type, boilerplate_options = {})
    @hash = boilerplate(type, boilerplate_options)
    generate
  end

  def generate
    @hash = convert_to_qbxml_hash
    xml = hash_to_xml(@hash, @options)
    handler = xml_handler(xml)
    @options[:doc] ? handler : handler.to_xml
  end

  def xml_handler(xml)
    doc = Nokogiri.XML(xml, nil, @options[:encoding] || 'utf-8')
    remove_tags_preserve_content(doc, REPEATABLE_KEY)
  end

  # Transforms to QBXML camelcase e.g. :first_name = FirstName
  # There are also special cases handled within ACRONYMS e.g. :list_id = ListID | != ListId
  def convert_to_qbxml_hash
    key_proc = lambda { |k| k.camelize.gsub(Regexp.union(ACRONYMS)) { |val| val.upcase }}
    deep_convert(@hash, &key_proc)
  end

  # Removes the parent Repeat node intended for repeatable
  # nodes like InvoiceLineAdd
  def remove_tags_preserve_content(doc, name)
    doc.xpath(".//#{name}").reverse.each do |element|
      element.children.reverse.each do |child|
        child_clone = child.clone
        element.add_next_sibling child_clone
        child.unlink
      end
      element.unlink
    end
    doc
  end

  def hash_to_xml(hash, opts = {})
    opts = opts.dup
    opts[:indent]          ||= 0
    opts[:root]            ||= :QBXML
    opts[:version]         ||= '7.0'
    opts[:attributes]      ||= (hash.delete(ATTR_ROOT) || {})
    opts[:builder]         ||= Builder::XmlMarkup.new(indent: opts[:indent])
    opts[:skip_types]      = true unless opts.key?(:skip_types) 
    opts[:skip_instruct]   = false unless opts.key?(:skip_instruct)
    builder = opts[:builder]

    unless opts.delete(:skip_instruct)
      builder.instruct!(:qbxml, version: opts[:version])
    end

    builder.tag!(opts[:root], opts.delete(:attributes)) do
      hash.each do |key, val|
        case val
        when Hash
          self.hash_to_xml(val, opts.merge({root: key, skip_instruct: true}))
        when Array
          val.map { |i| self.hash_to_xml(i, opts.merge({root: key, skip_instruct: true})) }
        else
          builder.tag!(key, val, {})
        end
      end

      yield builder if block_given?
    end
  end

  def boilerplate_header(type, action)
    "#{type}_#{action}"
  end

  def boilerplate(type, opts = {})
    head = boilerplate_header(type, opts[:action] || 'add')
    body_hash = opts[:action] == :query ? @hash : { head => @hash }
    {  :qbxml_msgs_rq =>
       [
         {
           :xml_attributes =>  { "onError" => opts[:on_error] || ON_ERROR},
           head + '_rq' =>
           [
             {
               :xml_attributes => { "requestID" => "#{opts[:request_id] || 1}" }.merge(opts[:attrs] || {})
             }.merge(body_hash)
           ]
         }
       ]
    }
  end

  private

  def deep_convert(hash, &block)
    hash.inject(Hash.new) do |h, (k,v)|
      k = k.to_s
      ignored = IGNORED_KEYS.include?(k) 
      if ignored
        h[k] = v
      else
        key = block_given? ? yield(k) : k
        h[key] = \
          case v
        when Hash
          deep_convert(v, &block)
        when Array
          v.map { |i| i.is_a?(Hash) ? deep_convert(i, &block) : i }
        else v
        end
      end; h
    end
  end

end
