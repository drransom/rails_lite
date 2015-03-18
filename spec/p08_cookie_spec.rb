require 'webrick'
require 'phase8/controller_base'
require 'phase8/flash'
require 'pry-byebug'

describe "rendering the flash" do
  let(:req) { WEBrick::HTTPRequest.new(Logger: nil) }
  let(:res) { WEBrick::HTTPResponse.new(HTTPVersion: '1.0') }
  let(:cook) { WEBrick::Cookie.new('_rails_lite_app_flash', { xyz: 'abc' }.to_json) }


  it "deserializes json cookie if one exists" do
    req.cookies << cook
    flash = Phase8::Flash.new(req)
    expect(flash[:xyz]).to eq 'abc'
    expect(flash.now[:xyz]).to eq 'abc'
  end

  describe '#store_flash' do
    context "without cookies in request" do
      before(:each) do
        flash = Phase8::Flash.new(req)
        flash[:first_key] = 'first_val'
        flash.store_flash(res)
      end

      it "adds new cookie with '_rails_lite_app_flash' name to response" do
        cookie = res.cookies.find { |c| c.name == '_rails_lite_app_flash' }
        expect(cookie).to_not be nil
      end

      it "stores the cookie in json format" do
        cookie = res.cookies.find { |c| c.name == '_rails_lite_app_flash' }
        JSON.parse(cookie.value).should be_a(Hash)
      end
    end

    context 'with cookies in request' do
      before(:each) do
        cook = WEBrick::Cookie.new('_rails_lite_app_flash',
          { pho: "soup" }.to_json)
        req.cookies << cook
      end

      it 'reads the flash data into the flash' do
        flash = Phase8::Flash.new(req)
        expect(flash[:pho]).to eq 'soup'
      end

      it 'reads the flash data into flash.now' do
        flash = Phase8::Flash.new(req)
        expect(flash.now[:pho]).to eq 'soup'
      end
    end

    context 'retreiving/saving flash data' do

      it 'finds data that was entered into flash.now' do
        flash = Phase8::Flash.new(req)
        flash.now[:errors] = 'This is a redirect error'
        expect(flash[:errors]). to eq 'This is a redirect error'
      end

      it 'saves flash data to the cookie' do
        flash = Phase8::Flash.new(req)
        flash[:errors] = 'This is a redirect error'
        flash.store_flash(res)
        cookie = res.cookies.find { |c| c.name == '_rails_lite_app_flash' }
        deserialized_value = JSON.parse(cookie.value)
        expect(deserialized_value['errors']). to eq 'This is a redirect error'
      end

      it 'does not save flash now data to the cookie' do
        flash = Phase8::Flash.new(req)
        flash[:errors] = 'This is a redirect error'
        flash.now[:errors] = 'This is an error to eq rendered immediately'
        flash.store_flash(res)
        cookie = res.cookies.find { |c| c.name == '_rails_lite_app_flash' }
        deserialized_value = JSON.parse(cookie.value)
        expect(deserialized_value['errors']). to eq 'This is a redirect error'
      end
    end
  end
end
