require 'postcode_sanitizer'

module ConstituencyApiHelpers
  module ApiLevel
    def stub_constituency(postcode, *constituency_params)
      constituency =
        if constituency_params.first.is_a? ConstituencyApi::Constituency
          constituency_params.first
        else
          ConstituencyApi::Constituency.new(*constituency_params)
        end
      allow(ConstituencyApi).to receive(:constituencies).
                                  with(PostcodeSanitizer.call(postcode)).
                                  and_return([constituency])
    end

    def stub_constituencies(partial_postcode, *constituencies)
      allow(ConstituencyApi).to receive(:constituencies).
                                  with(PostcodeSanitizer.call(partial_postcode)).
                                  and_return(constituencies)

    end

    def stub_no_constituencies(postcode)
      allow(ConstituencyApi).to receive(:constituencies).
                                  with(PostcodeSanitizer.call(postcode)).
                                  and_return([])
    end

    def stub_broken_api
      allow(ConstituencyApi).to receive(:constituencies).and_return([])
    end
  end

  module NetworkLevel
    def api_host
      ConstituencyApi::Client::API_HOST
    end

    def api_endpoint
      ConstituencyApi::Client::API_ENDPOINT
    end

    def api_url(postcode)
      "#{api_host}#{api_endpoint}" % { postcode: sanitize_and_escape_postcode(postcode) }
    end

    def sanitize_and_escape_postcode(postcode)
      Rack::Utils.escape_path(PostcodeSanitizer.call(postcode))
    end

    def stub_constituency_from_file(postcode, filename)
      stub_request(:get, api_url(postcode)).to_return(status: 200, body: IO.read(filename))
    end

    def stub_constituency(postcode, constituency_id, constituency_name, mp_id: '0001', mp_name: 'A. N. Other MP', mp_start_date: '2015-05-07T00:00:00')
      api_response = <<-RESPONSE.strip_heredoc
          <Constituencies>
            <Constituency>
              <Constituency_Id>#{ constituency_id }</Constituency_Id>
              <Name>#{ constituency_name }</Name>
              <RepresentingMembers>
                <RepresentingMember>
                  <Member_Id>#{ mp_id }</Member_Id>
                  <Member>#{ mp_name }</Member>
                  <StartDate>#{ mp_start_date }</StartDate>
                  <EndDate xsi:nil="true"
                           xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
                </RepresentingMember>
              </RepresentingMembers>
            </Constituency>
          </Constituencies>
        RESPONSE

      stub_request(:get, api_url(postcode)).to_return(status: 200, body: api_response)
    end

    def stub_no_constituencies(postcode)
      stub_constituency_from_file(postcode, Rails.root.join("spec", "fixtures", "constituency_api", "no_results.xml"))
    end

    def stub_broken_api
      stub_request(:get, %r[#{api_host}/*]).to_return(status: 500)
    end
  end
end
