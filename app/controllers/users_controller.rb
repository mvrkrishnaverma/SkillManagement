class UsersController < InheritedResources::Base
  before_filter :authenticate_user
  custom_actions :resource => :skills
  
  def dashboard
    @user = User.find(params[:id]) 
    @users = @user.similar_skill_users
  end
  
  def similar_skill
    @skill = Skill.find(params[:skill])
    @user = User.find(params[:id]) 
    @users = @user.similar_skill_users(@skill)
    render :dashboard  
  end
  
  def user_search
    @user = User.find(params[:id])
    if !params[:search].blank?
      @users = User.includes(:skills).where("skills.name like '%#{params[:search]}%' or users.name like '%#{params[:search]}%' or users.emp_id = '#{params[:search]}'" )
    else
      @users = @user.similar_skill_users
    end  
    render :dashboard
  end

  def skills
    @user = User.find(params[:id])
    @skill_set = SkillSet.new
  end
  
  def add_skills
    @user = User.find(params[:id])
    SkillSet.transaction do
      skill_sets = @user.skill_sets.map(&:id)
      SkillSet.where(:id => skill_sets).destroy_all
      unless params[:skill_ids].nil?
        params[:skill_ids].each_with_index do |skill,i|
          SkillSet.create(:user_id => @user.id, :skill_id => skill.to_i, :level => params[:level_ids][i] )  
        end
      end
    end
    flash[:notice] = "Skill successfully added"
    redirect_to profile_user_path(@user)
  end
  
  
  def search
    if !params[:search].blank?
      @users = User.includes(:skills).where("skills.name like '%#{params[:search]}%'")
    else
      @users = User.all
    end  
    render :index
  end
  
  def profile
    

    if !params[:id].blank? 
      @user = User.find(params[:id])
      if !@user.blank?
        emp_id = "#{@user.emp_id}"
      else
        emp_id = params[:id]    
      end
      ldap = Net::LDAP.new :host => '10.237.5.106',
      :port => 3268,
      :auth => {
        :method => :simple,
        :username => "systompun",
        :password => "password-1"
      }
       
      if !params[:view].blank?
        filter = Net::LDAP::Filter.eq("cn", params[:view])         
      else
        filter = Net::LDAP::Filter.eq("sAMAccountName", emp_id)
      end

      @user_details = Hash.new
      treebase = "dc=cts,dc=com"
      ldap.search(:base => treebase, :filter => filter) do |entry|
        entry.each do |attribute, values|
          values.each do |value|
            @user_details[attribute.to_sym] = value
          end
        end
      end
    end
    
  end
  
end
