require "../../spec_helper"

include ContextHelper

private class TestPage
  include Lucky::HTMLPage

  def render
  end

  def render_select(field)
    select_input field do
    end
    self
  end

  def render_disabled_select(field)
    select_input field, attrs: [:disabled] do
    end
    self
  end

  def render_multi_select(field)
    multi_select_input field do
    end
    self
  end

  def render_disabled_multi_select(field)
    multi_select_input field, attrs: [:disabled] do
    end
    self
  end

  def render_options(field, options)
    options_for_select(field, options)
    self
  end

  def render_prompt(label)
    select_prompt(label)
    self
  end

  def html
    view
  end
end

class SomeFormWithCompany
  def company_id
    Avram::PermittedAttribute(Int32).new(
      name: :company_id,
      param: "1",
      value: nil,
      param_key: "company"
    )
  end

  def tags
    Avram::PermittedAttribute(Array(String)).new(
      name: :tags,
      param: "",
      value: ["one", "two"],
      param_key: "company"
    )
  end

  def numbers
    Avram::PermittedAttribute(Array(Int32)).new(
      name: :numbers,
      param: "",
      value: [1, 2],
      param_key: "company"
    )
  end
end

describe Lucky::SelectHelpers do
  it "renders select" do
    view.render_select(form.company_id).html.to_s.should eq <<-HTML
    <select id="company_company_id" name="company:company_id"></select>
    HTML

    view.render_disabled_select(form.company_id).html.to_s.should eq <<-HTML
    <select id="company_company_id" name="company:company_id" disabled></select>
    HTML
  end

  it "renders multi-select" do
    view.render_multi_select(form.tags).html.to_s.should eq <<-HTML
    <select id="company_tags_0" name="company:tags[]" multiple></select>
    HTML

    view.render_disabled_multi_select(form.tags).html.to_s.should eq <<-HTML
    <select id="company_tags_0" name="company:tags[]" multiple disabled></select>
    HTML
  end

  it "renders options" do
    view.render_options(form.company_id, [{"Volvo", 2}, {"BMW", 3}, {"None", nil}])
      .html.to_s.should eq <<-HTML
      <option value="2">Volvo</option><option value="3">BMW</option><option value="">None</option>
      HTML
  end

  it "renders multi-select options" do
    view.render_options(form.tags, [{"One", "one"}, {"Two", "two"}, {"Three", "three"}])
      .html.to_s.should eq <<-HTML
      <option value="one" selected>One</option><option value="two" selected>Two</option><option value="three">Three</option>
      HTML
  end

  it "renders multi-select Int32 options" do
    view.render_options(form.numbers, [{"One", 1}, {"Two", 2}, {"Three", 3}])
      .html.to_s.should eq <<-HTML
      <option value="1" selected>One</option><option value="2" selected>Two</option><option value="3">Three</option>
      HTML
  end

  it "renders selected option" do
    view.render_options(form.company_id, [{"Volvo", 1}, {"BMW", 3}])
      .html.to_s.should eq <<-HTML
      <option value="1" selected>Volvo</option><option value="3">BMW</option>
      HTML
  end

  it "renders a blank option as a prompt" do
    view.render_prompt("Which one do you want?").html.to_s.should eq <<-HTML
    <option value="">Which one do you want?</option>
    HTML
  end
end

private def view
  TestPage.new(build_context)
end

private def form
  SomeFormWithCompany.new
end
