# encoding: utf-8

require 'spec_helper'

describe EtsBlog::Alerts do

  let(:fake_proxy) { EtsBlog::Alerts.new({fake: true}) }
  let(:empty_xml) { '<xml><node><chicken>egg</chicken></node></xml>' }
  let(:unexpected_xml) { '<xml><node><chicken>egg</chicken></node></xml>' }
  let(:xml_with_no_teaser){ Rails.root.join('fixtures', 'xml', 'app_alerts_feed_no_teaser.xml') }
  let(:xml_multibyte_characters) { Rails.root.join('fixtures', 'xml', 'app_alerts_feed_diacriticals.xml') }

  it 'should format and return the latest well-formed feed message' do
    alert = fake_proxy.get_latest
    alert[:title].should == 'CalCentral Scheduled Upgrade (Test Announce Only)'
    alert[:teaser].should == 'CalCentral Scheduled Upgrade (Test Announce Only)'
    alert[:url].should == 'http://ets-dev.berkeley.edu/news/calcentral-scheduled-upgrade-test-announce-only'
    alert[:timestamp][:epoch].should == 1393257625
  end

  context 'when the xml contains multibyte characters' do
    before { allow(fake_proxy).to receive(:get_feed).and_return(MultiXml.parse File.read(xml_multibyte_characters)) }
    it 'should parse' do
      fake_proxy.stub(:get_feed).and_return(MultiXml.parse File.read(xml_multibyte_characters))
      alert = fake_proxy.get_latest
      alert[:title].should == '¡El Señor González se zampó un extraño sándwich de vodka y ajo! (¢, ®, ™, ©, •, ÷, –, ¿)'
      alert[:url].should == 'hדג סקרן שט בים מאוכזב ולפתע מצא לו חברה'
      alert[:teaser].should == 'جامع الحروف عند البلغاء يطلق على الكلام المركب من جميع حروف التهجي بدون تكرار أحدها في لفظ واحد، أما في لفظين فهو جائز'
    end
  end

  context 'when the xml is missing a teaser' do
    before { allow(fake_proxy).to receive(:get_feed).and_return(MultiXml.parse File.read(xml_with_no_teaser)) }
    it 'should return non-teaser attributes' do
      alert = fake_proxy.get_latest
      expect(alert[:title]).to be_present
      expect(alert[:url]).to be_present
      expect(alert[:timestamp][:epoch]).to be_present
    end
  end

  context 'when xml data is empty' do
    before { allow(fake_proxy).to receive(:get_feed).and_return(MultiXml.parse empty_xml) }
    it 'should return blank' do
      expect(fake_proxy.get_latest).to eq ''
    end
  end

  context 'when xml data is unexpected' do
    before { allow(fake_proxy).to receive(:get_feed).and_return(MultiXml.parse unexpected_xml) }
    it 'should return blank' do
      expect(fake_proxy.get_latest).to eq ''
    end
  end

  context 'when xml data is nil' do
    before { allow(fake_proxy).to receive(:get_feed).and_return(MultiXml.parse nil) }
    it 'should return blank' do
      expect(fake_proxy.get_latest).to eq ''
    end
  end

  context 'when exceptions are raised' do
    before { allow(fake_proxy).to receive(:get_feed).and_raise(SocketError) }

    it 'should rescue exceptions and return nil from get_latest' do
      expect { fake_proxy.get_alerts }.to raise_exception
      expect { fake_proxy.get_latest }.not_to raise_exception
      expect(fake_proxy.get_latest).to be_nil
    end

    context 'caching failures' do
      include_context 'short-lived cache write of NilClass on failures'
      it 'should write to cache when handling exceptions' do
        expect { fake_proxy.get_latest }.not_to raise_exception
      end
    end
  end

end
