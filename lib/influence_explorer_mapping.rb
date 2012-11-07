require 'json'
require 'httparty'
require 'faraday/response/json_decoded'
require 'faraday/response/csv_translated'
require 'datajam/datacard'

module InfluenceExplorerMapping
  require 'influence_explorer_mapping/version'
  require 'influence_explorer_mapping/choice_fields'
  require 'influence_explorer_mapping/value_setters'

  class APIMapping < Datajam::Datacard::APIMapping::Base

    extend ChoiceFields
    extend ValueSetters

    name        "Influence Explorer"
    version     VERSION
    authors     "Dan Drinkard"
    email       "ddrinkard@sunlightfoundation.com"
    homepage    "http://datajam.org/datacards/influence-explorer"
    summary     "An API mapping to add Influence Explorer as a data source for card visualizations"
    description "IMPORTANT NOTE: This mapping does automatic name resolution of individuals, organizations and politicians. You MUST verify your results independently."
    base_uri    "http://transparencydata.com/api/1.0/"
    data_type   :json

    setting :apikey, label: "API Key", type: :string

    get :politician_contributors, "Politician - Contributors" do
      uri '/aggregates/pol/:entity_id/contributors.json'
      help_text 'Top organizations contributing to a politician'
      param :entity_id, label: "Politician" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :name, label: 'Contributor Name'
        field :type, label: 'Contributor Type'
        field :employee_count do
          value_getter{|val| val.to_i }
        end
        field :employee_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :direct_count do
          value_getter{|val| val.to_i }
        end
        field :direct_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :total_count do
          value_getter{|val| val.to_i }
        end
        field :total_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :politician_industries, "Politician - Industries" do
      uri '/aggregates/pol/:entity_id/contributors/industries.json'
      help_text 'Top industries contributing to a politician'
      param :entity_id, label: "Politician" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :name, label: 'Industry' do
          value_getter{|val| val.titleize }
        end
        field :count, label: 'Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :amount, format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :politician_unknown_industries, "Politician - Unknown Industries" do
      uri '/aggregates/pol/:entity_id/contributors/industries_unknown.json'
      help_text 'Contribution count and total for a politician from unknown industries'
      param :entity_id, label: "Politician" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      response do
        before_filter{|text| "[#{text}]" }
        field :count, label: 'Contribution Count' do
          value_getter{|val| val.to_f }
        end
        field :amount, label: 'Contribution Amount', format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :politician_local_breakdown, "Politician - Local Breakdown" do
      uri '/aggregates/pol/:entity_id/contributors/local_breakdown.json'
      help_text 'In-state vs out-of-state contributions to a politician. Display as table only.'
      param :entity_id, label: "Politician" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      response do
        before_filter{|text| "[#{text}]" }
        field :"in-state" do
          value_getter{|val| "#{val[0]} contributions ($#{val[1].to_f.to_delimited})"}
        end
        field :"out-of-state" do
          value_getter{|val| "#{val[0]} contributions ($#{val[1].to_f.to_delimited})"}
        end
      end
    end

    get :politician_type_breakdown, "Politician - Type Breakdown" do
      uri '/aggregates/pol/:entity_id/contributors/type_breakdown.json'
      help_text 'Individual vs organization contributions to a politician. Display as table only.'
      param :entity_id, label: "Politician" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      response do
        before_filter{|text| "[#{text}]" }
        field :Individuals do
          value_getter{|val| "#{val[0]} contributions ($#{val[1].to_f.to_delimited})"}
        end
        field :PACs, label: 'PACs' do
          value_getter{|val| "#{val[0]} contributions ($#{val[1].to_f.to_delimited})"}
        end
      end
    end

    get :politician_fec_summary, "Politician - FEC Summary" do
      uri '/aggregates/pol/:entity_id/fec_summary.json'
      help_text 'The latest figures from the FEC\'s summary report.'
      param :entity_id, label: "Politician" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      response do
        before_filter{|text| "[#{text}]"}
        field :office do
          value_getter{|val| {'P' => 'President', 'H' => 'House', 'S' => 'Senate' }[val] }
        end
        field :total_raised, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :contributions_pac, label: 'PAC Contributions', format: :currency do
          value_getter{|val| val.to_f }
        end
        field :contributions_candidate, label: 'Candidate Contributions', format: :currency do
          value_getter{|val| val.to_f }
        end
        field :contributions_indiv, label: 'Individual Contributions', format: :currency do
          value_getter{|val| val.to_f }
        end
        field :contributions_party, label: 'Party Contributions', format: :currency do
          value_getter{|val| val.to_f }
        end
        field :transfers_in, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :cash_on_hand, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :disbursements, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :total_receipts_rank
        field :total_disbursements_rank
        field :max_rank, label: 'Rankings Out Of'
        field :date, label: 'Date of report' do
          value_getter{|val| Date.parse val }
        end
      end
    end

    get :politician_fec_indexp, "Politician - FEC Independent Expenditures" do
      uri '/aggregates/pol/:entity_id/fec_indexp.json'
      help_text 'Top independent expenditures for and against a politician.'
      param :entity_id, label: "Politician" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      response do
        field :committee_name do
          value_getter{|val| val.titleize }
        end
        field :amount, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :support_oppose, label: 'Support/Oppose'
      end
    end

    get :individual_org_recipients, "Individual - Top Organization Recipients" do
      uri '/aggregates/indiv/:entity_id/recipient_orgs.json'
      help_text 'Top organizations receiving contributions from an individual.'
      param :entity_id, label: "Individual" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :recipient_name do
          value_getter{|val| val.titleize }
        end
        field :count, label: 'Number of Contributions' do
          value_getter{|val| val.to_i }
        end
        field :amount, format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :individual_pol_recipients, "Individual - Top Politician Recipients" do
      uri '/aggregates/indiv/:entity_id/recipient_pols.json'
      help_text 'Top politicians receiving contributions from an individual.'
      param :entity_id, label: "Individual" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :recipient_name do
          value_getter{|val| val.titleize }
        end
        field :party
        field :state
        field :count, label: 'Number of Contributions' do
          value_getter{|val| val.to_i }
        end
        field :amount, format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :individual_party_breakdown, "Individual - Party Breakdown" do
      uri '/aggregates/indiv/:entity_id/recipients/party_breakdown.json'
      help_text 'Amounts contributed to each party by an individual.'
      param :entity_id, label: "Individual" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      response do
        before_filter do |text|
          response = []
          struct = JSON.parse(text)
          response << {'party' => 'Democrats', 'count' => struct["Democrats"][0].to_i, 'amount' => struct["Democrats"][1].to_f } rescue nil
          response << {'party' => 'Republicans', 'count' => struct["Republicans"][0].to_i, 'amount' => struct["Republicans"][1].to_f } rescue nil
          response << {'party' => 'Other', 'count' => struct["Other"][0].to_i, 'amount' => struct["Other"][1].to_f } rescue nil
          JSON.dump(response)
        end
        field :party
        field :count, label: 'Number of contributions'
        field :amount, label: 'Total', format: :currency
      end
    end

    get :individual_registrants, "Individual - Lobbying Registrants" do
      uri '/aggregates/indiv/:entity_id/registrants.json'
      help_text 'Lobbying firms that employed an individual.'
      param :entity_id, label: "Individual" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :registrant_name
        field :count, label: 'Number of Records' do
          value_getter{|val| val.to_i }
        end
      end
    end

    get :individual_clients, "Individual - Clients" do
      uri '/aggregates/indiv/:entity_id/clients.json'
      help_text 'Clients an individual (lobbyist) was contracted to work for.'
      param :entity_id, label: "Individual" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :client_name
        field :count, label: 'Number of Records' do
          value_getter{|val| val.to_i }
        end
      end
    end

    get :individual_issues, "Individual - Issues" do
      uri '/aggregates/indiv/:entity_id/issues.json'
      help_text 'Issues an individual (lobbyist) has worked on.'
      param :entity_id, label: "Individual" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :issue
        field :count, label: 'Number of Records' do
          value_getter{|val| val.to_i }
        end
      end
    end

    get :organization_recipients, "Organization - Top Recipients" do
      uri '/aggregates/org/:entity_id/recipients.json'
      help_text 'Top politicians receiving contributions from an organization.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :name, label: 'Recipient Name'
        field :party do
          value_getter{|val| APIMapping.parties[val] }
        end
        field :employee_count, label: 'Employee Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :employee_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :direct_count, label: 'Direct Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :direct_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :total_count, label: 'Total Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :total_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :organization_pac_recipients, "Organization - PAC Recipiemts" do
      uri '/aggregates/org/:entity_id/recipient_pacs.json'
      help_text 'Top PACs receiving contributions from an organization.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :name, label: 'Organization Name' do
          value_getter{|val| val.titleize }
        end
        field :employee_count, label: 'Employee Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :employee_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :direct_count, label: 'Direct Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :direct_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :total_count, label: 'Total Contribution Count' do
          value_getter{|val| val.to_i}
        end
        field :total_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :organization_party_breakdown, "Organization - Party Breakdown" do
      uri '/aggregates/org/:entity_id/recipients/party_breakdown.json'
      help_text 'Amounts contributed to each party by an organization.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      response do
        before_filter do |text|
          response = []
          struct = JSON.parse(text)
          response << {'party' => 'Democrats', 'count' => struct["Democrats"][0].to_i, 'amount' => struct["Democrats"][1].to_f }
          response << {'party' => 'Republicans', 'count' => struct["Republicans"][0].to_i, 'amount' => struct["Republicans"][1].to_f }
          response << {'party' => 'Other', 'count' => struct["Other"][0].to_i, 'amount' => struct["Other"][1].to_f }
          JSON.dump(response)
        end
        field :party
        field :count, label: 'Number of contributions'
        field :amount, label: 'Total', format: :currency
      end
    end

    get :organization_level_breakdown, "Organization - Level Breakdown" do
      uri '/aggregates/org/:entity_id/recipients/level_breakdown.json'
      help_text 'Amounts contributed to state vs federal levels by an organization.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      response do
        before_filter do |text|
          response = []
          struct = JSON.parse(text)
          response << {'party' => 'Federal', 'count' => struct["Federal"][0].to_i, 'amount' => struct["Federal"][1].to_f }
          response << {'party' => 'State', 'count' => struct["State"][0].to_i, 'amount' => struct["State"][1].to_f }
          JSON.dump(response)
        end
        field :party
        field :count, label: 'Number of contributions'
        field :amount, label: 'Total', format: :currency
      end
    end

    get :organization_registrants, "Organization - Lobbying Registrants" do
      uri '/aggregates/org/:entity_id/registrants.json'
      help_text 'Lobbying firms hired by an organization'
      param :entity_id, label: "Individual" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :registrant_name
        field :count, label: 'Number of Records' do
          value_getter{|val| val.to_i }
        end
      end
    end

    get :organization_issues, "Organization - Issues" do
      uri '/aggregates/org/:entity_id/issues.json'
      help_text 'Issues an organization has hired lobbyists for.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :issue
        field :count, label: 'Number of Records' do
          value_getter{|val| val.to_i }
        end
      end
    end

    get :organization_bills, "Organization - Bills" do
      uri '/aggregates/org/:entity_id/bills.json'
      help_text 'Bills an organization has lobbied on.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :bill_name, label: 'Bill Number'
        field :title, label: 'Bill Title'
        field :congress_no, label: 'Congress'
        field :count, label: 'Number of Records'
      end
    end

    get :organization_lobbyists, "Organization - Lobbyists" do
      uri '/aggregates/org/:entity_id/lobbyists.json'
      help_text 'Lobbyists hired by an organization.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :lobbyist_name do
          value_getter{|val| val.titleize }
        end
        field :count, label: 'Number of Records'
      end
    end

    get :organization_registrant_clients, "Organization - Registrant Clients" do
      uri '/aggregates/org/:entity_id/registrant/clients.json'
      help_text 'Clients that hired an organization to lobby, if organization is a lobbying firm.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      response do
        field :client_name do
          value_getter{|val| val.titleize }
        end
        field :count, label: 'Number of Records'
        field :amount, format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :organization_registrant_issues, "Organization - Registrant Issues" do
      uri '/aggregates/org/:entity_id/registrant/issues.json'
      help_text 'Issues an organization has lobbied on, if organizataion is a lobbying firm.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :issue
        field :count, label: 'Number of Records' do
          value_getter{|val| val.to_i }
        end
      end
    end

    get :organization_registrant_bills, "Organization - Registrant Bills" do
      uri '/aggregates/org/:entity_id/registrant/bills.json'
      help_text 'Bills an organization has lobbied on, if organization is a lobbying firm.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :bill_name, label: 'Bill Number'
        field :title, label: 'Bill Title'
        field :congress_no, label: 'Congress'
        field :count, label: 'Number of Records'
      end
    end

    get :organization_registrant_lobbyists, "Organization - Registrant Lobbyists" do
      uri '/aggregates/org/:entity_id/registrant/lobbyists.json'
      help_text 'Lobbyists employed by an organization.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :lobbyist_name do
          value_getter{|val| val.titleize }
        end
        field :count, label: 'Number of Records'
      end
    end

    get :industry_orgs, "Industry - Top Organizations" do
      uri '/aggregates/industry/:entity_id/orgs.json'
      help_text 'Top organizations in an industry by dollars contributed.'
      param :entity_id, label: "Industry" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :name, label: 'Organization Name'
        field :employee_count, label: 'Employee Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :employee_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :direct_count, label: 'Direct Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :direct_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :total_count, label: 'Total Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :total_amount, format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :organization_regs_matches, "Organization - Mentions in Regulations" do
      uri '/aggregates/org/:entity_id/regulations_text.json'
      help_text 'Regulatory dockets that most frequently mention an organization.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :agency
        field :docket
        field :title
        field :year
        field :count, label: 'Mentions'
      end
    end

    get :organization_regs_submissions, "Organization - Regulations Submissions" do
      uri '/aggregates/org/:entity_id/regulations_submitter.json'
      help_text 'Regulatory dockets with the most submissions from an organization.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :agency
        field :docket
        field :title
        field :year
        field :count, label: 'Submissions'
      end
    end

    get :organization_faca_memberships, "Organization - FACA Memberships" do
      uri '/aggregates/org/:entity_id/faca.json'
      help_text 'Employee memberships on federal advisory committees for an organization.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(1990)
      param :limit, label: 'Number of Results', default: 10
      response do
        field :agency_name
        field :member_count, label: 'Employees on a Committee'
        field :committee_count, label: 'Committees Served on'
      end
    end

    get :organization_fec_summary, "Organization - FEC summary" do
      uri '/aggregates/org/:entity_id/fec_summary.json'
      help_text 'Latest figures for an organization from the FEC\'s summary report.'
      param :entity_id, label: "Organization" do
        value_setter{|val| APIMapping.lookup_entity_id val }
        validate{|val| !(val =~ /^[0-9a-f]+$/).nil? }
      end
      response do
        before_filter{|text| "[#{text}]" }
        field :contributions_from_indiv, label: 'Contributions from Individuals', format: :currency do
          value_getter{|val| val.to_f }
        end
        field :contributions_from_pacs, label: 'Contributions from PACs', format: :currency do
          value_getter{|val| val.to_f }
        end
        field :loans_received, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :nonfederal_transfers_received, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :transfers_from_affiliates, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :total_raised, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :cash_on_hand, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :disbursements, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :party_coordinated_expenditures_made, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :contributions_to_committees, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :independent_expenditures_made, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :nonfederal_expenditure_share, format: :currency do
          value_getter{|val| val.to_f }
        end
        field :debts, format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :top_individuals, "Top Individual Contributors" do
      uri '/aggregates/indivs/top_:limit.json'
      help_text 'Top n individual contributors in a cycle, without regard to party'
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(2000).merge('-1' => 'All available')
      param :limit, label: 'Number of Results'
      response do
        field :name, label: 'Contributor' do
          value_getter{|val| val.titleize }
        end
        field :count, label: 'Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :amount, label: 'Total', format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :top_organizations, "Top Organizations by Contributions" do
      uri '/aggregates/orgs/top_:limit.json'
      help_text 'Top n organizations by contribution dollars in a cycle'
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(2000).merge('-1' => 'All available')
      param :limit, label: 'Number of Results'
      response do
        field :name, label: 'Organization' do
          value_getter{|val| val.titleize }
        end
        field :count, label: 'Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :amount, label: 'Total', format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :top_politicians, "Top Politicians by Contributions Received, All Offices" do
      uri '/aggregates/pols/top_:limit.json'
      help_text 'Top n politicians by contribution dollars received in a cycle'
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(2000).merge('-1' => 'All available')
      param :limit, label: 'Number of Results'
      response do
        field :name, label: 'Recipient' do
          value_getter{|val| val.titleize }
        end
        field :state
        field :seat, label: 'Office Sought' do
          value_getter{|val| APIMapping.seats[val] || val.split(':').join(' ,').titleize }
        end
        field :party do
          value_getter{|val| APIMapping.parties[val] || "Other" }
        end
        field :count, label: 'Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :amount, label: 'Total', format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

    get :top_industries, "Top Industries by Amount Contributed" do
      uri '/aggregates/industries/top_:limit.json'
      help_text 'Top n Industries by the amount contributed in a given cycle'
      param :cycle, label: 'Election Cycle', type: :select, options: APIMapping.election_cycles_since(2000).merge('-1' => 'All available')
      param :limit, label: 'Number of Results'
      response do
        field :name, label: 'Industry' do
          value_getter{|val| val.titleize }
        end
        field :count, label: 'Contribution Count' do
          value_getter{|val| val.to_i }
        end
        field :amount, label: 'Total', format: :currency do
          value_getter{|val| val.to_f }
        end
      end
    end

  end  # APIMapping
end  # InfluenceExplorerMapping