
class AdminController < ApplicationController
  layout 'ontology'
  before_action :cache_setup

  DEBUG_BLACKLIST = [:"$,", :$ADDITIONAL_ONTOLOGY_DETAILS, :$rdebug_state, :$PROGRAM_NAME, :$LOADED_FEATURES, :$KCODE, :$-i, :$rails_rake_task, :$$, :$gems_build_rake_task, :$daemons_stop_proc, :$VERBOSE, :$DAEMONS_ARGV, :$daemons_sigterm, :$DEBUG_BEFORE, :$stdout, :$-0, :$-l, :$-I, :$DEBUG, :$', :$gems_rake_task, :$_, :$CODERAY_DEBUG, :$-F, :$", :$0, :$=, :$FILENAME, :$?, :$!, :$rdebug_in_irb, :$-K, :$TESTING, :$fileutils_rb_have_lchmod, :$EMAIL_EXCEPTIONS, :$binding, :$-v, :$>, :$SAFE, :$/, :$fileutils_rb_have_lchown, :$-p, :$-W, :$:, :$__dbg_interface, :$stderr, :$\, :$&, :$<, :$debug, :$;, :$~, :$-a, :$DEBUG_RDOC, :$CGI_ENV, :$LOAD_PATH, :$-d, :$*, :$., :$-w, :$+, :$@, :$`, :$stdin, :$1, :$2, :$3, :$4, :$5, :$6, :$7, :$8, :$9]
  ADMIN_URL = "#{LinkedData::Client.settings.rest_url}/admin/"
  ONTOLOGIES_URL = "#{ADMIN_URL}ontologies_report"
  REPORT_NEVER_GENERATED = "NEVER GENERATED"

  def index
    if session[:user].nil? || !session[:user].admin?
      redirect_to :controller => 'login', :action => 'index', :redirect => '/admin'
    else
      response = _ontologies_report
      render action: "index"
    end
  end

  def submissions
    @submissions = nil
    @acronym = params["acronym"]
    @ontology = LinkedData::Client::Models::Ontology.find_by_acronym(params["acronym"]).first
    begin
      submissions = @ontology.explore.submissions
      @submissions = submissions.sort {|a,b| b.submissionId <=> a.submissionId }
    rescue
      @submissions = []
    end
    render :partial => "layouts/ontology_report_submissions"
  end

  def clearcache
    response = {errors: '', success: ''}

    if @cache.respond_to?(:flush_all)
      begin
        @cache.flush_all
        response[:success] = "Cache successfully flushed"
      rescue Exception => e
        response[:errors] = "Problem flushing the cache - #{e.message}"
      end
    else
      response[:errors] = "The cache does not respond to the 'flush_all' command"
    end
    render :json => response
  end

  def resetcache
    response = {errors: '', success: ''}

    if @cache.respond_to?(:reset)
      begin
        @cache.reset
        response[:success] = "Cache connection successfully reset"
      rescue Exception => e
        response[:errors] = "Problem resetting the cache connection - #{e.message}"
      end
    else
      response[:errors] = "The cache does not respond to the 'reset' command"
    end
    render :json => response
  end

  def ontologies_report
    response = _ontologies_report
    render :json => response
  end

  def refresh_ontologies_report
    response = {errors: '', success: ''}

    begin
      response_raw = LinkedData::Client::HTTP.post(ONTOLOGIES_URL, {}, raw: true)
      response = JSON.parse(response_raw, :symbolize_names => true)
      response[:success] = "Refresh of ontologies report started successfully";
    rescue Exception => e
      response[:errors] = "Problem refreshing report - #{e.message}"
    end
    render :json => response
  end

  def delete_ontologies
    response = {errors: '', success: ''}

    if params["ontologies"].nil? || params["ontologies"].empty?
      response[:errors] = "No ontologies parameter passed. Syntax: ?ontologies=ONT1,ONT2,...,ONTN"
    else
      ontologies = params["ontologies"].split(",").map {|o| o.strip}

      ontologies.each do |ont|
        begin
          ontology = LinkedData::Client::Models::Ontology.find_by_acronym(ont).first

          if ontology
            error_response = ontology.delete

            if error_response
              errors = response_errors(error_response) # see application_controller::response_errors
              _process_errors(errors, response, false)
            else
              response[:success] << "Ontology #{ont} and all its artifacts deleted successfully, "
            end
          else
            response[:errors] << "Ontology #{ont} was not found in the system, "
          end
        rescue Exception => e
          response[:errors] << "Problem deleting ontology #{ont} - #{e.message}, "
        end
      end
      response[:success] = response[:success][0...-2] unless response[:success].empty?
      response[:errors] = response[:errors][0...-2] unless response[:errors].empty?
    end
    render :json => response
  end

  def delete_submission
    response = {errors: '', success: ''}

    begin
      ont = params["acronym"]
      ontology = LinkedData::Client::Models::Ontology.find_by_acronym(ont).first

      if ontology
        submissions = ontology.explore.submissions
        submission = submissions.select {|o| o.submissionId == params["id"].to_i}.first

        if submission
          error_response = submission.delete

          if error_response
            errors = response_errors(error_response) # see application_controller::response_errors
            _process_errors(errors, response, true)
          else
            response[:success] << "Submission #{params["id"]} for ontology #{ont} was deleted successfully"
          end
        else
          response[:errors] << "Submission #{params["id"]} for ontology #{ont} was not found in the system"
        end
      else
        response[:errors] << "Ontology #{ont} was not found in the system"
      end
    rescue Exception => e
      response[:errors] << "Problem deleting submission #{params["id"]} for ontology #{ont} - #{e.message}"
    end
    render :json => response
  end

  private

  def cache_setup
    @cache = Rails.cache.instance_variable_get("@data")
  end

  def _ontologies_report
    response = {ontologies: Hash.new, date_generated: REPORT_NEVER_GENERATED, errors: '', success: ''}
    start = Time.now

    begin
      ontologies_data = LinkedData::Client::HTTP.get(ONTOLOGIES_URL, {}, raw: true)
      ontologies_data_parsed = JSON.parse(ontologies_data, :symbolize_names => true)

      if ontologies_data_parsed[:errors]
        _process_errors(ontologies_data_parsed[:errors], response, true)
      else
        response.merge!(ontologies_data_parsed)
        response[:success] = "Report successfully regenerated on #{ontologies_data_parsed[:date_generated]}"
        LOG.add :debug, "Ontologies Report - retrieved #{response[:ontologies].length} ontologies in #{Time.now - start}s"
      end
    rescue Exception => e
      response[:errors] = "Problem retrieving ontologies report - #{e.message}"
    end
    @data = response
    response
  end

  def _process_errors(errors, response, remove_trailing_comma=true)
    if errors.is_a?(Hash)
      errors.each {|_, v| response[:errors] << "#{v}, "}
    elsif errors.kind_of?(Array)
      errors.each {|err| response[:errors] << "#{err}, "}
    end
    response[:errors] = response[:errors][0...-2] if remove_trailing_comma
  end

end
