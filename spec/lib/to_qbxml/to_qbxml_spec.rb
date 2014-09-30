require 'spec_helper'

describe ToQbxml do
  let(:repeat_key) { ToQbxml::REPEATABLE_KEY }

  context 'add or modify requests' do
    it "should remove all Repeat parent tags and correctly identify line item descriptions" do
      hash = { repeat: [ line_item(1), line_item(2) ] }
      n = ToQbxml.new(hash, doc: true).make(:invoice)
      expect(n.at('InvoiceLineAdd:first > Desc').content).to eq 'Line 1'
      expect(n.at('InvoiceLineAdd:last > Desc').content).to eq 'Line 2'
      expect(n.css(repeat_key)).to be_empty
    end

    it "should make a mod invoice" do
      n = ToQbxml.new({}, doc: true).make(:invoice, action: :mod)
      expect(n.css('InvoiceModRq')).to be_present
      expect(n.css('InvoiceMod')).to be_present
    end

    it "should be able to change the onError status" do
      n = ToQbxml.new({}, doc: true).make(:invoice, on_error: 'continueOnError')
      expect(n.at('QBXMLMsgsRq')['onError']).to eq 'continueOnError'
    end

    it "should be able to manipulate a mod requests attributes" do
      n = ToQbxml.new({}, doc: true).make(:customer, action: :mod, attrs: { 'requestID' => 27, 'iterator' => 'Start' })
      expect(n.at('CustomerModRq')['requestID']).to eq '27'
      expect(n.at('CustomerModRq')['iterator']).to eq 'Start'
    end

    it "should remove all parent tags with a node just having the word 'repeat' a part of it" do
      hash = { word_with_repeat: [ line_item(1), line_item(2) ] }
      xml = ToQbxml.new(hash).make(:invoice)
      expect(xml).to match /\<WordWithRepeat/
    end

    it "should be qbxml version 12" do
      xml = ToQbxml.new({}, version: '12.0').generate
      expect(xml).to match /version=\"12\.0/
    end

    it "should have the default encoding of utf-8" do
      xml = ToQbxml.new({}).generate
      expect(xml).to match /encoding=\"utf-8/
    end

    it "should be able to change the default encoding" do
      xml = ToQbxml.new({}, encoding: 'windows-1251').generate
      expect(xml).to match /encoding=\"windows-1251/
    end
  end

  context 'query requests' do
    it 'makes a simple iterator query request' do
      n = ToQbxml.new({}, doc: true).make(:customer, action: :query, attrs: { 'iterator' => 'Start'})
      #puts n.to_xml
      expect(n.at('CustomerQueryRq')['iterator']).to eq 'Start'
    end

    it 'makes a complete query request' do
      hash = {
        include_line_items: true,
        modified_date_range_filter: { 
          from_modified_date: '2003-02-14T00:00:00',
          to_modified_date: '2003-04-14T00:00:00'
        }
      }
      n = ToQbxml.new(hash, doc: true).make(:invoice, action: :query)
      #puts n.to_xml
      expect(n.at('InvoiceQueryRq > IncludeLineItems').content).to eq 'true'
      expect(n.at('InvoiceQueryRq > ModifiedDateRangeFilter > FromModifiedDate').content).to eq hash[:modified_date_range_filter][:from_modified_date]
      expect(n.at('InvoiceQueryRq > ModifiedDateRangeFilter > ToModifiedDate').content).to eq hash[:modified_date_range_filter][:to_modified_date]
    end
  end

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
end
