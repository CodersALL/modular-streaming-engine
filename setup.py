from setuptools import setup, Extension
from Cython.Build import cythonize

extensions = [
    Extension(
        "bucket_search",
        ["bucket_search.pyx"],
        extra_compile_args=["-O3", "-march=native", "-std=c++11"],
        language="c++"  # This forces g++ compilation
    )
]
setup(
    ext_modules=cythonize(extensions, compiler_directives={"language_level": "3"})
)



