class HomeController < ApplicationController
  def index
    loc = Geocoder.search(request.ip)
    if loc.length then
      loc = loc.first
      @default_loc = "#{loc.city}, #{loc.region_code}".strip
      @default_loc = "San Francisco, CA" if @default_loc.length == 1
    else
      @default_loc = "San Francisco, CA"
    end
  end

  def search
    query = params[:query] || ""
    near = params[:near] || ""
    count = params[:count] || "20"

    query.strip!
    near.strip!
    count.strip!

    empty = query == "" and near == ""

    @count = count.to_i
    @count = 10 if @count < 10
    @count = 100 if @count > 100

    if near == nil or near.strip.length == 0 then
      logger.info "Searching IP address #{request.ip}"
      loc = Geocoder.search(request.ip)
    else
      logger.info "Searching for #{near}"
      loc = Geocoder.search(near)
    end

    if loc.length then
      loc = loc.first
      logger.info "#{loc}"
      @default_loc = "#{loc.city}".strip
      @default_loc = "San Francisco" if @default_loc.length == 0
    else
      @default_loc = "San Francisco"
    end

    logger.info "Searching #{@default_loc}"
    loc = Geocoder.search(@default_loc).first
    @loc = loc
    logger.info "Searching #{@default_loc}"
    near = loc.city

    # logger.info "Searching #{query} near #{loc.latitude},#{loc.longitude}"
    # @pics = flickr.photos.search :text => query, :accuracy => 15, :lat => loc.latitude, :lon => loc.longitude,
    #                              :per_page => 20, :extras => 'url_sq'

    if not empty
      tank = IndexTank::Client.new '<indextank API URL>'
      idx = tank.indexes 'test'

      query_str = ""
      query_str += "name:\"#{query}\"" if query != ""
      query_str += " city:\"#{near}\""

      @results = idx.search query_str,
                          :fetch => 'docid,name,address,city,state,postcode,telephone,fax,category,website,latitude,longitude',
                          :function => 5,
                          :var0 => loc.latitude,
                          :var1 => loc.longitude,
                          :len => @count

      logger.info "query: #{query_str}; near #{loc.city} => #{loc.latitude},#{loc.longitude}; len #{@count}; ip #{request.ip}"


      @results['results'].reject! { |item| item['latitude'] == '' }
      @nresults_total = @results['results'].length

      @results['results'] = @results['results'].group_by { |item| item['category'] }
      @results['results'] = @results['results'].to_a.sort { |a,b| b[1].length <=> a[1].length }

      @results
    else
      @results = {"results" => [], "matches" => -1}
    end
  end

  def maps
    self.search
  end

  def edit
    logger.info "Edit called with params => #{params}"
    api = Factual::Api.new :api_key => FACTUAL_API_KEY
    table = api.get_table FACTUAL_TABLE
    table.input :docid => params[:docid],
                :ip => request.ip,
                :key => params[:key],
                :value => params[:update_value],
                :time => Time.now
    render :text => "#{params[:update_value]} (Curated)"
  end
end
