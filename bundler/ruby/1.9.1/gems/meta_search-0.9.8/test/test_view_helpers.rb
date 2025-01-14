require 'helper'
require 'action_controller'
require 'action_view/test_case'

class TestViewHelpers < ActionView::TestCase
  tests MetaSearch::Helpers::FormHelper
  include MetaSearch::Helpers::UrlHelper

  router = ActionDispatch::Routing::RouteSet.new
  router.draw do
    resources :developers
    resources :companies
    resources :projects
    resources :notes
    match ':controller(/:action(/:id(.:format)))'
  end
  include router.url_helpers

  def setup
    @controller = Class.new do

      attr_reader :url_for_options
      def url_for(options)
        @url_for_options = options
        "http://www.example.com"
      end

      def _routes
        @routes ||= ActionDispatch::Routing::RouteSet.new
      end
    end
    @controller = @controller.new
  end

  context "A previously-filled search form" do
    setup do
      @s = Company.search
      @s.created_at_gte = [2001, 2, 3, 4, 5]
      @s.name_contains = "bacon"
      form_for @s do |f|
        @f = f
      end
    end

    should "retain previous search terms" do
      html = @f.datetime_select(:created_at_gte)
      ['2001', '3', '04', '05'].each do |v|
        assert_match /<option selected="selected" value="#{v}">#{v}<\/option>/,
                     html
      end
      assert_match /<option selected="selected" value="2">February<\/option>/, html
      assert_dom_equal '<input id="search_name_contains" name="search[name_contains]" ' +
                       'size="30" type="text" value="bacon" />',
                        @f.text_field(:name_contains)
    end
  end

  context "A form using mutiparameter_field with default size option" do
    setup do
      @s = Developer.search
      form_for @s do |f|
        @f = f
      end
    end

    should "apply proper cast and default size attribute to text fields" do
      html = @f.multiparameter_field :salary_in,
             {:field_type => :text_field, :type_cast => 'i'},
             {:field_type => :text_field, :type_cast => 'i'}, :size => 10
      assert_dom_equal '<input id="search_salary_in(1i)" name="search[salary_in(1i)]" ' +
                       'size="10" type="text" />' +
                       '<input id="search_salary_in(2i)" name="search[salary_in(2i)]" ' +
                       'size="10" type="text" />',
                       html
    end
  end

  context "A form using checks with three choices" do
    setup do
      @s = Company.search
      form_for @s do |f|
        @f = f
      end
    end

    should "return an array of check boxes without a block" do
      assert @f.checks(:id_in, [['One', 1], ['Two', 2], ['Three', 3]]).all?{|c| c.is_a?(MetaSearch::Check)}
    end

    should "generate the expected HTML with a block" do
      expected = <<-EXPECTED
<p>
  <label for="search_id_in_1">One</label>
  <input id="search_id_in_1" name="search[id_in][]" type="checkbox" value="1" />
</p>
<p>
  <label for="search_id_in_2">Two</label>
  <input id="search_id_in_2" name="search[id_in][]" type="checkbox" value="2" />
</p>
<p>
  <label for="search_id_in_3">Three</label>
  <input id="search_id_in_3" name="search[id_in][]" type="checkbox" value="3" />
</p>
      EXPECTED
      assert_dom_equal expected,
        render(:to => :string, :inline => <<-ERB)
<%= @f.checks(:id_in, [['One', 1], ['Two', 2], ['Three', 3]]) do |c| -%>
<p>
  <%= c.label %>
  <%= c.box %>
</p>
<% end -%>
      ERB
    end
  end

  context "A form using checks with three choices and a previous selection" do
    setup do
      @s = Company.search
      @s.id_in = [1, 3]
      form_for @s do |f|
        @f = f
      end
    end

    should "return an array of check boxes without a block" do
      assert @f.checks(:id_in, [['One', 1], ['Two', 2], ['Three', 3]]).all?{|c| c.is_a?(MetaSearch::Check)}
    end

    should "generate the expected HTML with a block" do
      expected = <<-EXPECTED
<p>
  <label for="search_id_in_1">One</label>
  <input id="search_id_in_1" name="search[id_in][]" type="checkbox" value="1" checked="checked" />
</p>
<p>
  <label for="search_id_in_2">Two</label>
  <input id="search_id_in_2" name="search[id_in][]" type="checkbox" value="2" />
</p>
<p>
  <label for="search_id_in_3">Three</label>
  <input id="search_id_in_3" name="search[id_in][]" type="checkbox" value="3" checked="checked" />
</p>
      EXPECTED
      assert_dom_equal expected,
                       render(:to => :string, :inline => <<-ERB)
<%= @f.checks(:id_in, [['One', 1], ['Two', 2], ['Three', 3]]) do |c| -%>
<p>
  <%= c.label %>
  <%= c.box %>
</p>
<% end -%>
                       ERB
    end
  end

  context "A form using collection_checks with companies" do
    setup do
      @s = Company.search
      form_for @s do |f|
        @f = f
      end
    end

    should "return an array of check boxes without a block" do
     assert @f.collection_checks(:id_in, Company.all, :id, :name).all?{|c| c.is_a?(MetaSearch::Check)}
    end

    should "generate the expected HTML with a block" do
      @f.collection_checks(:id_in, Company.all, :id, :name) do |c|
        concat render :to => :string, :inline => "<p><%= c.label %> <%= c.box %></p>", :locals => {:c => c}
      end
      assert_dom_equal output_buffer,
                       '<p><label for="search_id_in_1">Initech</label> ' +
                       '<input id="search_id_in_1" name="search[id_in][]" type="checkbox" value="1" /></p>' +
                       '<p><label for="search_id_in_2">Advanced Optical Solutions</label> ' +
                       '<input id="search_id_in_2" name="search[id_in][]" type="checkbox" value="2" /></p>' +
                       '<p><label for="search_id_in_3">Mission Data</label> ' +
                       '<input id="search_id_in_3" name="search[id_in][]" type="checkbox" value="3" /></p>'
    end
  end

  context "A company search form sorted by name ascending" do
    setup do
      @s = Company.search
      @s.meta_sort = 'name.asc'
      form_for @s do |f|
        @f = f
      end
    end

    should "generate a sort link with an up arrow for the sorted column" do
      assert_match /Name &#9650;/,
                   @f.sort_link(:name, :controller => 'companies')
    end

    should "not generate a sort link with an up arrow for a non-sorted column" do
      assert_no_match /Created at &#9650;/,
                      @f.sort_link(:created_at, :controller => 'companies')
    end
  end

  context "A company search" do
    setup do
      @s = Company.search
    end

    context "sorted by name ascending" do
      setup do
        @s.meta_sort = 'name.asc'
      end

      should "generate a sort link with an up arrow for the sorted column" do
        assert_match /Name &#9650;/,
                     sort_link(@s, :name, :controller => 'companies')
      end

      should "not generate a sort link with an up arrow for a non-sorted column" do
        assert_no_match /Created at &#9650;/,
                        sort_link(@s, :created_at, :controller => 'companies')
      end

      context "with existing search options" do
        setup do
          @s.name_contains = 'a'
        end

        should "maintain previous search options in its sort links" do
          assert_match /search\[name_contains\]=a/,
                       sort_link(@s, :name, :controller => 'companies')
        end
      end
    end
  end

  context "A developer search" do
    setup do
      @s = Developer.search
    end

    context "sorted by company name descending" do
      setup do
        @s.meta_sort = 'company_name.desc'
      end

      should "generate a sort link with a down arrow for the sorted column" do
        assert_match /Company name &#9660;/,
                     sort_link(@s, :company_name, :controller => 'developers')
      end

      should "not generate a sort link with a down arrow for a non-sorted column" do
        assert_no_match /Created at &#9660;/,
                        sort_link(@s, :created_at, :controller => 'developers')
      end

      context "with existing search options" do
        setup do
          @s.name_contains = 'a'
        end

        should "maintain previous search options in its sort links" do
          assert_match /search\[name_contains\]=a/,
                       sort_link(@s, :company_name, :controller => 'companies')
        end
      end
    end
  end
end