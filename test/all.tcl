package require tcltest
namespace import ::tcltest::configure ::tcltest::runAllTests
configure -testdir [file dirname [info script]]
runAllTests
