cmake_minimum_required(VERSION 2.6.0)

# set up pods
set(POD_NAME drake)
include(cmake/pods.cmake)

include(cmake/matlab_pods.cmake)
pods_configure_matlab_paths()

if ( APPLE )
   set(osdir mac64)
elseif (UNIX)
   set(osdir linux64)
else()
  message(FATAL_ERROR "this pod only supports gurobi on mac64 and
   linux64.  you will have to install gurobi manually:
   http://www.gurobi.com/download/gurobi-optimizer")
endif()

set(GUROBI_HOME ${CMAKE_CURRENT_SOURCE_DIR}/gurobi602/${osdir})

install(FILES ${GUROBI_HOME}/include/gurobi_c.h
	      	    ${GUROBI_HOME}/include/gurobi_c++.h
                    DESTINATION include)
install(FILES ${GUROBI_HOME}/lib/libgurobi60.so
	            ${GUROBI_HOME}/lib/libgurobi_c++.a
		    ${GUROBI_HOME}/lib/libgurobi_g++4.2.a
		    DESTINATION lib)
if (APPLE)
   # tell matlab where to look for the library (see bug 1704 for a detailed explanation)
   execute_process(COMMAND install_name_tool -change "libgurobi60.so" "@loader_path/../lib/libgurobi60.so" gurobi.mexmaci64
   			   WORKING_DIRECTORY ${GUROBI_HOME}/matlab)
   execute_process(COMMAND install_name_tool -id ${CMAKE_INSTALL_PREFIX}/lib/libgurobi60.so  ${GUROBI_HOME}/lib/libgurobi60.so)

elseif (UNIX)
   install(FILES ${GUROBI_HOME}/lib/libgurobi.so.6.0.2 DESTINATION lib)
endif()

pods_install_bash_setup(gurobi
  "export GUROBI_HOME=${GUROBI_HOME}\n"
  "export PATH=\${PATH}:\${GUROBI_HOME}/bin\n"
  "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:\${GUROBI_HOME}/lib\n"
)

message(STATUS "Writing addpath_gurobi.m and rmpath_gurobi.m to ${CMAKE_INSTALL_PREFIX}/matlab")
file(WRITE ${CMAKE_INSTALL_PREFIX}/matlab/addpath_gurobi.m
	   "function addpath_gurobi()\n"
#	   "  setenv('GUROBI_HOME','${GUROBI_HOME}');\n"
	   "  addpath('${GUROBI_HOME}/matlab');\n"
	   "  \n"
	   "  % gurobi.mex* is loaded, now test for license issues\n"
	   "  model.obj = 1;\n"
	   "  model.A  = sparse(1,1);\n"
	   "  model.rhs = 0;\n"
	   "  model.sense = '=';\n"
	   "  params.outputflag = false;\n"
	   "  result = gurobi(model, params);\n"
    )

file(WRITE ${CMAKE_INSTALL_PREFIX}/matlab/rmpath_gurobi.m
	   "function rmpath_gurobi()\n"
	   "  rmpath('${GUROBI_HOME}/matlab');\n"
    )

pods_install_pkg_config_file(gurobi
  VERSION 6.0.2
  DESCRIPTION "Gurobi Optimizer"
  LIBS "-lgurobi60"
)
