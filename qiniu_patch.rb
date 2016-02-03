require 'qiniu'
require 'qiniu/http'
require 'qiniu/config'
module Qiniu
  class << self
    def list_prefix bucket, prefix, marker, limit
      uri = get_prefix_uri bucket, prefix, marker, limit
      HTTP.management_post(uri)
    end

    def get_prefix_uri bucket, prefix = nil, marker = nil, limit = nil
      uri = Config.settings[:rsf_host] + '/' + 'list?' + 'bucket=' + bucket
      if marker
        uri += '&' + 'marker=' + marker.to_s
      end

      if limit
        uri += '&' + 'limit=' + limit.to_s
      end

      if prefix
        uri += '&' + 'prefix=' + prefix.to_s
      end

      return uri
    end
  end
end