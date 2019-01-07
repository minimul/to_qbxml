# ToQbxml

ToQbxml creates QuickBooks XML Requests from a Ruby Hash

## Installation

Add this line to your application's Gemfile:

    gem 'to_qbxml'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install to_qbxml

## Usage

### Configuration
```
ToQbxml.configure do |config|
  config.version = '11.0'
  config.on_error = 'continueOnError'
end

```

### Create an add request
```ruby
  def line_item(line_number)
    {
      invoice_line_add: {
        item_ref: {
          list_id: '3243'
        },
        desc: "Line #{line_number}",
        amount: 10.99,
        is_taxable: true,
        quantity: 3,
        rate_percent: 0,
        repeat: [{
          line: {
            desc: 'inside'
          }
        }]
      }
    }
  end
  hash = { repeat: [ line_item(1), line_item(2) ] }
  xml = ToQbxml.new(hash).make(:invoice)
  puts xml
```

```xml
<?xml version="1.0" encoding="US-ASCII"?>
<?qbxml version="13.0"?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    <InvoiceAddRq requestID="1">
      <InvoiceAdd>
        <InvoiceLineAdd>
          <ItemRef>
            <ListID>3243</ListID>
          </ItemRef>
          <Desc>Line 1</Desc>
          <Amount>10.99</Amount>
          <IsTaxable>true</IsTaxable>
          <Quantity>3</Quantity>
          <RatePercent>0</RatePercent>
          <Line>
            <Desc>inside</Desc>
          </Line>
        </InvoiceLineAdd>
        <InvoiceLineAdd>
          <ItemRef>
            <ListID>3243</ListID>
          </ItemRef>
          <Desc>Line 2</Desc>
          <Amount>10.99</Amount>
          <IsTaxable>true</IsTaxable>
          <Quantity>3</Quantity>
          <RatePercent>0</RatePercent>
          <Line>
            <Desc>inside</Desc>
          </Line>
        </InvoiceLineAdd>
      </InvoiceAdd>
    </InvoiceAddRq>
  </QBXMLMsgsRq>
</QBXML>
```

### Notes on creating repeating nodes
Use the parent node *repeat* to make repeating nodes such as *InvoiceLineAdd* and *Line*
, therefore, the hash key will be **repeat** followed by an array of hashes.
```ruby
  hash = { 
    repeat: [ 
      line: {
        desc: 'Line 1'
      },
      line: {
        desc: 'Line 2'
      }
    ] 
  }
```

### Create a mod request
```ruby
  xml = ToQbxml.new({}).make(:invoice, action: :mod)
  puts xml
```

```xml
<?xml version="1.0" encoding="US-ASCII"?>
<?qbxml version="13.0"?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    <InvoiceModRq requestID="1">
      <InvoiceMod/>
    </InvoiceModRq>
  </QBXMLMsgsRq>
</QBXML>
```


### Create a query request using QBXML version 12
```ruby
  hash = {
    include_line_items: true,
    modified_date_range_filter: { 
      from_modified_date: '2003-02-14T00:00:00',
      to_modified_date: '2003-04-14T00:00:00'
    }
  }
  xml = ToQbxml.new(hash, version: '12.0').make(:invoice, action: :query)
  puts xml
```

```xml
<?xml version="1.0" encoding="US-ASCII"?>
<?qbxml version="12.0"?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    <InvoiceQueryRq requestID="1">
      <IncludeLineItems>true</IncludeLineItems>
      <ModifiedDateRangeFilter>
        <FromModifiedDate>2003-02-14T00:00:00</FromModifiedDate>
        <ToModifiedDate>2003-04-14T00:00:00</ToModifiedDate>
      </ModifiedDateRangeFilter>
    </InvoiceQueryRq>
  </QBXMLMsgsRq>
</QBXML>
```

### Create an iterator query request returning a Nokogiri Document instead of XML
```ruby
  n = ToQbxml.new({}, doc: true).make(:customer, action: :query, attrs: { 'iterator' => 'Start'})
  puts n.at('CustomerQueryRq')['iterator']
  ## Output = 'Start'
  puts n.to_xml
```

```xml
<?xml version="1.0" encoding="US-ASCII"?>
<?qbxml version="13.0"?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    <CustomerQueryRq requestID="1" iterator="Start"/>
  </QBXMLMsgsRq>
</QBXML>
```

### Notes on using the **attrs** options
This attributes hash will not be converted to QBXML camelcase so you must supply this yourself. Also, it is best to keep the attrs consistent using an *old school* Ruby Hash with String key e.g.
```ruby
attrs = { 'requestID' => 34, 'iterator' => 'Continue', 'iteratorID' => '{2343333-434343334}' }
```

### The *initialize* method
Takes 2 arguments:

1. a Hash. This is to be the body of the QBXML request.
2. a Hash of options. See this [method](https://github.com/minimul/to_qbxml/blob/master/lib/to_qbxml/to_qbxml.rb#L54) for a full list.

### The *make* method
Takes 2 arguments:

1. The desired QBXML request in a snakecased Symbol or String. For example, ```.make(:sales_tax_code)``` equals SalesTaxCode
2. a Hash of options. See this [method](https://github.com/minimul/to_qbxml/blob/master/lib/to_qbxml/to_qbxml.rb#L89) for a full list.

### Examples:
See the [specs](https://github.com/minimul/to_qbxml/blob/master/spec/lib/to_qbxml/to_qbxml_spec.rb) for more examples

### What about encoding?

This library is hard coded for US-ASCII because that is what is accepted by the QBSDK. Fool around with UTF-8 at your own peril.

### What about validation?
This library provides no validation or schema validation. In my experience, it is best to use the [OCR docs](http://developer-static.intuit.com/qbsdk-current/common/newosr/index.html) and the [QBXML validator and SDKTest utilities](https://developer.intuit.com/docs/0250_qb/0010_get_oriented/0060_sdk_components) that come bundled with the standard QBSDK installation. These tools are only available on Windows but if you are wanting to do any serious integration with QuickBooks Desktop then you better have a Windows machine or VM handy. 

### What about reading and parsing QBXML?
I suggest using Nokogiri. See the [specs](https://github.com/minimul/to_qbxml/blob/master/spec/lib/to_qbxml/to_qbxml_spec.rb) for using Nokogiri to parse QBXML.
Here are some quick examples:

#### Given
```xml
<?xml version="1.0" encoding="US-ASCII"?>
<?qbxml version="13.0"?>
<QBXML>
  <QBXMLMsgsRq onError="stopOnError">
    <InvoiceAddRq requestID="1">
      <InvoiceAdd>
        <InvoiceLineAdd>
          <ItemRef>
            <ListID>3243</ListID>
          </ItemRef>
          <Desc>Line 1</Desc>
          <Amount>10.99</Amount>
          <IsTaxable>true</IsTaxable>
          <Quantity>3</Quantity>
          <RatePercent>0</RatePercent>
          <Line>
            <Desc>inside</Desc>
          </Line>
        </InvoiceLineAdd>
        <InvoiceLineAdd>
          <ItemRef>
            <ListID>3243</ListID>
          </ItemRef>
          <Desc>Line 2</Desc>
          <Amount>10.99</Amount>
          <IsTaxable>true</IsTaxable>
          <Quantity>3</Quantity>
          <RatePercent>0</RatePercent>
          <Line>
            <Desc>inside</Desc>
          </Line>
        </InvoiceLineAdd>
      </InvoiceAdd>
    </InvoiceAddRq>
  </QBXMLMsgsRq>
</QBXML>
```

```
  xml = qbxml_example_for_above
  n = Nokogiri::XML(xml)
  expect(n.css('InvoiceLineAdd').size).to eq 2
  expect(n.at('InvoiceLineAdd:last > Desc').content).to eq 'Line 2'
```

  


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
