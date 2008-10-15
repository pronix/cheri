/***** BEGIN LICENSE BLOCK *****
 * 
 * Copyright (C) 2007,2008 William N Dortch <bill.dortch@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 ***** END LICENSE BLOCK *****/

package org.cheri;

import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.javasupport.JavaSupport;
import org.jruby.runtime.builtin.IRubyObject;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.WeakHashMap;

public final class RuntimeResources {

    private static final Map RUNTIME_RESOURCES = Collections.synchronizedMap(new WeakHashMap());
    
    public static RuntimeResources getResources(Ruby runtime) {
        if (runtime == null) throw new NullPointerException("null 'runtime' arg");
        RuntimeResources rr;
        synchronized(RUNTIME_RESOURCES) {
            if ((rr = (RuntimeResources)RUNTIME_RESOURCES.get(runtime)) == null) {
                rr = new RuntimeResources(runtime);
                RUNTIME_RESOURCES.put(runtime, rr);
            }
        }
        return rr;
    }

    public static RuntimeResources getResources(IRubyObject any) {
        if (any == null) throw new NullPointerException("null 'any' arg");
        return getResources(any.getRuntime());
    }

    private final Ruby runtime;
    private final JavaSupport javaSupport;
    private final Map namedResources = Collections.synchronizedMap(new HashMap());
    private final Map classInfo = new HashMap(128);
    private RubyModule cheriModule;
    private RubyModule cheriBuilderModule;
    private RubyModule javaModule; // Cheri::Java, not top-level Java
    private RubyModule javaUtilModule; // Cheri::Java::Util
    private RubyModule javaBuilderModule;
    private RubyModule javaUtilities;
    private RubyModule modFrame;
    private RubyModule modBuilder;
    private RubyModule modMarkup;
    
    private RuntimeResources(Ruby runtime) {
        this.runtime = runtime;
        this.javaSupport = runtime.getJavaSupport();
    }

    public Ruby getRuntime() {
        return runtime;
    }
    
    public RubyModule getCheri() {
        return cheriModule;
    }

    public void setCheri(RubyModule cheriModule) {
        if (this.cheriModule == null) {
            this.cheriModule = cheriModule;
        }
    }

    public RubyModule getJava() {
        return javaModule;
    }

    public void setJava(RubyModule javaModule) {
        if (this.javaModule == null) {
            this.javaModule = javaModule;
        }
    }

    public RubyModule getJavaUtil() {
        return javaUtilModule;
    }

    public void setJavaUtil(RubyModule javaUtilModule) {
        if (this.javaUtilModule == null) {
            this.javaUtilModule = javaUtilModule;
        }
    }

    public RubyModule getJavaBuilder() {
        return javaBuilderModule;
    }

    public void setJavaBuilder(RubyModule javaBuilderModule) {
        if (this.javaBuilderModule == null) {
            this.javaBuilderModule = javaBuilderModule;
        }
    }

    public RubyModule getCheriBuilder() {
        return cheriBuilderModule;
    }

    public void setCheriBuilder(RubyModule cheriBuilderModule) {
        if (this.cheriBuilderModule == null) {
            this.cheriBuilderModule = cheriBuilderModule;
        }
    }
    
    public RubyModule getModFrame() {
        return modFrame;
    }
    
    
    public void setModFrame(RubyModule modFrame) {
        if (this.modFrame == null) {
            this.modFrame = modFrame;
        }
    }
    
    public RubyModule getModBuilder() {
        return modBuilder;
    }

    public void setModBuilder(RubyModule modBuilder) {
        if (this.modBuilder == null) {
            this.modBuilder = modBuilder;
        }
    }
    
    public RubyModule getModMarkup() {
        return modMarkup;
    }

    public void setModMarkup(RubyModule modMarkup) {
        if (this.modMarkup == null) {
            this.modMarkup = modMarkup;
        }
    }
    
    public RubyModule getJavaUtilities() {
        if (javaUtilities == null) {
            // force (JRuby) Java module autoload
            runtime.getModule("Java");
            javaUtilities = runtime.getJavaSupport().getJavaUtilitiesModule();
        }
        return javaUtilities;
    }
    
    public JavaSupport getJavaSupport() {
        return javaSupport;
    }
    
    public Class loadJavaClass(final String name) {
        return javaSupport.loadJavaClass(name);
    }

    public Map getClassInfo() {
        return classInfo;
    }

    public Object get(String name) {
        return namedResources.get(name);
    }

    public void put(String name, Object value) {
        namedResources.put(name, value);
    }
}
