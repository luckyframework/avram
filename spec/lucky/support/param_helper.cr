module ParamHelper
  include ContextHelper

  def build_params(data : String, content_type : String = "application/x-www-form-urlencoded") : Lucky::Params
    req = build_request(method: "POST", body: data, content_type: content_type)
    Lucky::Params.new(req)
  end
end
