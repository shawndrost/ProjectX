require 'spec_helper'

describe "LayoutLinks" do
  
  it "should have a Home page at '/'" do
    get '/'
    response.should have_selector('title', :content => "Home")
  end
  
  it "should have a Contact page at '/contact'" do
    get '/contact'
    response.should have_selector('title', :content => "Contact")
  end
  
  it "should have an About page at '/about'" do
    get '/about'
    response.should have_selector('title', :content => "About")
  end
  
  it "should have a Help page at '/help'" do
    get '/help'
    response.should have_selector('title', :content => "Help")
  end
  
  it "should have a Sign Up page at '/signup'" do
    get '/signup'
    response.should have_selector('title', :content => "Sign Up")
  end
  
  it "should have the right links on the layout" do
    visit root_path
    click_link "About"
    response.should have_selector('title', :content => "About")
    click_link "Home"
    response.should have_selector('title', :content => "Home")
    click_link "Contact"
    response.should have_selector('title', :content => "Contact")
    visit root_path
    click_link "Sign up now!"
    response.should have_selector('title', :content => "Sign Up")
  end
  
  describe "when not signed in" do
    it "should have a signin link" do
      visit root_path
      response.should have_selector("a", :href => signin_path,
                                         :content => "Sign in")
    end
  end
  
  describe "when signed in" do
    
    before(:each) do
      @user = Factory(:user)
      visit signin_path
      fill_in :email, :with => @user.email
      fill_in :password, :with => @user.password
      click_button
    end
    
    it "should have a signout link" do
      visit root_path
      response.should have_selector("a", :href => signout_path, :content => "Sign out")
    end 

    it "should have a profile link" do
      visit root_path
      response.should have_selector("a", :href => user_path(@user),
                                         :content => "Profile")
    end 
    
    it "should have an events link" do
      visit root_path
      response.should have_selector("a", :href => events_path,
                                         :content => "Events")
    end
    
    describe "on events page" do
      
      it "should have a create event button" do
        visit events_path
        response.should have_selector("form", :method => "post", 
                                              :action => "/create_event")
      end
      
      it "should have a show my events button" do
        visit events_path
        response.should have_selector("form", :method => "post", 
                                              :action => "/my_events")
      end
    end
    
    describe "as admin" do
      
      before(:each) do
        @user.toggle!(:admin)
        visit root_path
      end
      
      it "should have a users link" do
        visit root_path
        response.should have_selector("a", :href => users_path,
                                           :content => "Users")
      end
    end                                     
  end
end