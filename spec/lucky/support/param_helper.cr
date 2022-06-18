module ParamHelper
  include ContextHelper

  def build_params(query_string : String) : Lucky::Params
    req = build_request(method: "POST", body: query_string)
    Lucky::Params.new(req)
  end
end
