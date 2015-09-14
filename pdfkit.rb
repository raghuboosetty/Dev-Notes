module Pdfkit
  def resume_pdf(resume)
    
    # kit.stylesheets << "#{Rails.root}/app/assets/stylesheets/application.css"
    filename = resume.first_name.gsub(" ", "-") + "-" + resume.last_name
    
    to_pdf
    filename
  end
  
  def to_pdf(name, options={})
    kit = PDFKit.new( render_to_string( layout: false , 
                                        partial: "/applicants/resume_content", 
                                        locals: { resume: resume }))    
   kit.to_file("public/" + filename + ".pdf")
  end
end