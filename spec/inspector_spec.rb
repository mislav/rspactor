require 'rspactor/inspector'

describe RSpactor::Inspector do
  before(:all) do
    @inspector = described_class.new('/project')
  end
  
  def translate(file)
    @inspector.translate(file)
  end
  
  describe "#translate" do
    it "should consider all controllers when application_controller changes" do
      translate('/project/app/controllers/application_controller.rb').should == ['spec/controllers']
      translate('/project/app/controllers/application.rb').should == ['spec/controllers']
    end
    
    it "should translate files under 'app/' directory" do
      translate('/project/app/controllers/foo_controller.rb').should ==
        ['spec/controllers/foo_controller_spec.rb']
    end
    
    it "should translate templates" do
      translate('/project/app/views/foo/bar.erb').should == ['spec/views/foo/bar.erb_spec.rb']
      translate('/project/app/views/foo/bar.html.haml').should ==
        ['spec/views/foo/bar.html.haml_spec.rb', 'spec/views/foo/bar.html_spec.rb']
    end
    
    it "should consider all views when application_helper changes" do
      translate('/project/app/helpers/application_helper.rb').should == ['spec/helpers', 'spec/views']
    end
    
    it "should consider related templates when a helper changes" do
      translate('/project/app/helpers/foo_helper.rb').should ==
        ['spec/helpers/foo_helper_spec.rb', 'spec/views/foo']
    end
    
    it "should translate files under deep 'lib/' directory" do
      translate('/project/lib/awesum/rox.rb').should ==
        ['spec/lib/awesum/rox_spec.rb', 'spec/awesum/rox_spec.rb', 'spec/rox_spec.rb']
    end
    
    it "should translate files under shallow 'lib/' directory" do
      translate('lib/runner.rb').should == ['spec/lib/runner_spec.rb', 'spec/runner_spec.rb']
    end
    
    it "should handle relative paths" do
      translate('foo.rb').should == ['spec/foo_spec.rb']
    end
    
    it "should handle files without extension" do
      translate('foo').should == ['spec/foo_spec.rb']
    end
    
    it "should consider all controllers, helpers and views when routes.rb changes" do
      translate('config/routes.rb').should == ['spec/controllers', 'spec/helpers', 'spec/views']
    end
    
    it "should consider all models when config/database.yml changes" do
      translate('config/database.yml').should == ['spec/models']
    end
    
    it "should consider all models when db/schema.rb changes" do
      translate('db/schema.rb').should == ['spec/models']
    end
    
    it "should consider related model when its observer changes" do
      translate('app/models/user_observer.rb').should == ['spec/models/user_observer_spec.rb', 'spec/models/user_spec.rb']
    end
    
    it "should consider all specs when spec_helper changes" do
      translate('spec/spec_helper.rb').should == ['spec']
    end
    
    it "should consider all specs when code under spec/shared/ changes" do
      translate('spec/shared/foo.rb').should == ['spec']
    end
    
    it "should consider all specs when app configuration changes" do
      translate('config/environment.rb').should == ['spec']
      translate('config/environments/test.rb').should == ['spec']
      translate('config/boot.rb').should == ['spec']
    end
  end
  
  describe "#determine_spec_files" do
    def determine(file)
      @inspector.determine_spec_files(file)
    end
    
    it "should filter out files that don't exist on the filesystem" do
      @inspector.should_receive(:translate).with('foo').and_return(%w(valid_spec.rb invalid_spec.rb))
      File.should_receive(:exists?).with('valid_spec.rb').and_return(true)
      File.should_receive(:exists?).with('invalid_spec.rb').and_return(false)
      determine('foo').should == ['valid_spec.rb']
    end
    
    it "should filter out files in subdirectories that are already on the list" do
      @inspector.should_receive(:translate).with('foo').and_return(%w(
        spec/foo_spec.rb
        spec/views/moo/bar_spec.rb
        spec/views/baa/boo_spec.rb
        spec/models/baz_spec.rb
        spec/controllers/moo_spec.rb
        spec/models
        spec/controllers
        spec/views/baa
      ))
      File.stub!(:exists?).and_return(true)
      determine('foo').should == %w(
        spec/foo_spec.rb
        spec/views/moo/bar_spec.rb
        spec/models
        spec/controllers
        spec/views/baa
      )
    end
  end
end