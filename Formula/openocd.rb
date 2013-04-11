require 'formula'

class Openocd < Formula
  homepage 'http://sourceforge.net/projects/openocd/'
  url 'http://downloads.sourceforge.net/project/openocd/openocd/0.6.1/openocd-0.6.1.tar.bz2'
  sha1 'b286dd9c0c6ca5cc7a76d25e404ad99a488e2c61'
  head 'git://git.code.sf.net/p/openocd/code'

  option 'enable-ft2232_libftdi', 'Enable building support for FT2232 based devices with libftdi driver'
  option 'enable-ft2232_ftd2xx',  'Enable building support for FT2232 based devices with FTD2XX driver'

  depends_on 'libusb-compat'
  depends_on 'libftdi' if build.include? 'enable-ft2232_libftdi'
  depends_on 'libtool' if build.head?
  depends_on 'automake' if build.head?

  def install
    # default options that don't imply additional dependencies
    args = %W[
      --enable-ftdi
      --enable-arm-jtag-ew
      --enable-jlink
      --enable-rlink
      --enable-stlink
      --enable-ulink
      --enable-usbprog
      --enable-vsllink
      --enable-ep93xx
      --enable-at91rm9200
      --enable-ecosboard
      --enable-opendous
      --enable-osbdm
      --enable-buspirate
    ]

    if build.include? "enable-ft2232_libftdi"
      args << "--enable-ft2232_libftdi"
      args << "--enable-presto_libftdi"
      args << "--enable-usb_blaster_libftdi"
    end

    if build.include? "enable-ft2232_ftd2xx"
      args << "--enable-ft2232_ftd2xx"
      args << "--enable-presto_ftd2xx"
    end

    if build.head?
      args << "--enable-maintainer-mode"
      system "./bootstrap", "nosubmodule"
    end

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          *args
    system "make install"
  end

  def patches
    DATA
  end
end

__END__
diff --git a/lib/cc.tcl b/lib/cc.tcl
index 7410d60..cd033c6 100644
--- a/jimtcl/autosetup/cc.tcl
+++ b/jimtcl/autosetup/cc.tcl
@@ -501,14 +501,8 @@ proc cctest {args} {
 		set tmp conftest__.o
 		lappend cmdline -c
 	}
-	lappend cmdline {*}$opts(-cflags)
+	lappend cmdline {*}$opts(-cflags) {*}[get-define cc-default-debug ""]
 
-	switch -glob -- [get-define host] {
-		*-*-darwin* {
-			# Don't generate .dSYM directories
-			lappend cmdline -gstabs
-		}
-	}
 	lappend cmdline $src -o $tmp {*}$opts(-libs)
 
 	# At this point we have the complete command line and the
@@ -688,6 +682,16 @@ if {[get-define CXX] ne "false"} {
 }
 msg-result "Build C compiler...[get-define CC_FOR_BUILD]"
 
+# On Darwin, we prefer to use -gstabs to avoid creating .dSYM directories
+# but some compilers don't support -gstabs, so test for it here.
+switch -glob -- [get-define host] {
+	*-*-darwin* {
+		if {[cctest -cflags {-gstabs}]} {
+			define cc-default-debug -gstabs
+		}
+	}
+}
+
 if {![cc-check-includes stdlib.h]} {
 	user-error "Compiler does not work. See config.log"
 }
