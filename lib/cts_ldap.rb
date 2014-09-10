/*LDAP moduel code */
require 'net/ldap'
require 'odbc'



module CTS_LDAP
  class LdapResponse
    attr_accessor :message, :success, :user
    def success?; success; end
  end
 
  class Ldap
    attr_accessor :ldap_connection, :params, :ldap_response

    def initialize(params = {})
      self.ldap_connection = connect_to_ldap_server()
      self.ldap_response = LdapResponse.new()
      self.params = params
    end

    def verify_ldap_authentication
      cts_user = params[:user][:username] if params[:user]
      cts_pass = params[:user][:password] if params[:user]

      #filter = Net::LDAP::Filter.eq("sAMAccountName",cts_user) if cts_user
      filter = Net::LDAP::Filter.eq(AppConfig[:ldap_search_filter], cts_user) if cts_user
      #treebase = "dc=cts,dc=com"
      treebase = AppConfig[:ldap_treebase]

      user_details = Hash.new
      #authenticate_ldap_user = true
      authenticate_ldap_user = ldap_connection.bind_as(:base => treebase, :filter => filter, :password => cts_pass)

      if authenticate_ldap_user
        user_details = ldap_user_search(ldap_connection, cts_user)
        @profile = {}
        params[:user][:password_confirmation] = cts_pass
        params[:user][:email] = user_details[:mail]
        @profile[:designation] = user_details[:title]
        @profile[:department] = user_details[:department]
        @profile[:first_name] = user_details[:givenname]
        # @profile[:last_name] = user_details[:sn]
        # @profile[:location] = user_details[:l]
        register_ldap_user if !check_record_and_update_passwd(user_details[:mail], cts_pass)
      else
        set_errored_response()
      end
      ldap_response
    end

    def set_errored_response(message = "The user name or password you entered isn't correct. Try entering it again.")
      ldap_response.message = message
      ldap_response.success = false
    end

    def set_success_response(message = "Successful signin")
      ldap_response.message = message
      ldap_response.success = true
    end

    def check_record_and_update_passwd(email, password)
      @user = User.find_by_email(email)
      @user = User.find_by_email(email.downcase) if !@user
      if @user
        if @user.username != nil
          @user.update_with_password(params[:user])
        else
          @user.accept_invitation!(params[:user])
          @user.seed_aspects
        end
        ldap_response.user = @user
        set_success_response("Signed in")
      else
        false
      end
    end

        #Search for mail in cts addressbook
    def search_addressbook
      emails = Array.new     
      flag = params[:q].to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
      id_search = false
      if flag
        filter = params[:q].length == 6 ? Net::LDAP::Filter.eq( "sAMAccountName", "#{params[:q]}" ) : ""
        id_search = true
      else
        filter = Net::LDAP::Filter.eq( "mail", "*#{params[:q]}*")
      end
      unless filter == ""
        ldap_connection.search( :base => AppConfig[:ldap_treebase], :filter => filter , :attributes => ["sAMAccountName", "mail"], :size => 10) do |entry|
          emails << {:name => "#{entry[:mail].first} (#{entry[:samaccountname].first})" , :value => entry[:mail].first}
        end
      end
      emails
    end

    def connect_to_ldap_server
      ldap = Net::LDAP.new :host => AppConfig[:ldap_host],
        :port => AppConfig[:ldap_port],
        :auth => {
          :method => :simple,
          :username => AppConfig[:ldap_username],
          :password => AppConfig[:ldap_password]
        }
     
      ldap
    end

    def ldap_user_search(ldap, user_id)
      user_details = Hash.new
      filter = Net::LDAP::Filter.eq("sAMAccountName", user_id)
      treebase = "dc=cts,dc=com"

      ldap.search(:base => treebase, :filter => filter, :attributes => ['mail', 'title', 'department', 'displayname', 'l', 'givenname', 'sn']) do |entry|
        entry.each do |attribute, values|
          values.each do |value|
            user_details[attribute.to_sym] = value
          end
        end
      end

      user_details
    end

    def register_ldap_user
      @user = User.build(params[:user])
      if @user.save
        @user.profile.first_name = @profile[:first_name]
        @user.profile.last_name = @profile[:last_name]
        @user.profile.department = @profile[:department]
        # ODBC.connect(AppConfig[:manlog_dsn_name], AppConfig[:manlog_username], AppConfig[:manlog_pwd]) do |dbc|
          # associate_details = dbc.run("select * from #{AppConfig[:manlog_table_name]} where associate_id = '#{@user.username}'")
          # associate_details.fetch_hash do |associate_detail|
            # if associate_detail
              # @user.profile.designation = associate_detail["designation"]
              # @user.profile.location = associate_detail["LOCATION"]
              # @user.profile.city = associate_detail["CITY"]
              # @user.profile.date_of_join = associate_detail["DATE_OF_JOIN"]
              # @user.profile.birthday = associate_detail["DATE_OF_BIRTH"].to_s.split(" ")[0]
              # unless ProjectInformation.find_by_profile_id_and_project_id(@user.profile.id, associate_detail["project_id"])
                # ProjectInformation.create(:profile_id => @user.profile.id, :project_id =>  associate_detail["project_id"], :project_name =>  associate_detail["project_name"] )
              # end
#
              # unless AccountInformation.find_by_profile_id_and_account_id(@user.profile.id, associate_detail["account_id"])
                # AccountInformation.create(:profile_id => @user.profile.id, :account_id =>  associate_detail["account_id"], :account_name =>  associate_detail["account_name"] )
              # end
            # else
              # @user.profile.designation = @profile[:designation]
              # @user.profile.location = @profile[:location]
            # end
          # end
        # end
        @user.profile.searchable = true
        @user.profile.save
        @user.seed_aspects
        ldap_response.user = @user  
        set_success_response("Signed in")
      else
        @user.errors.delete(:person)
        set_errored_response(@user.errors.full_messages.join(";"))
      end
    end
  end
end