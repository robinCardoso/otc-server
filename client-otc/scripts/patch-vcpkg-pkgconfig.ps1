# Usa pkg-config do MSYS2 local; evita download MSYS2 i686 obsoleto (404 em libwinpthread)
$VcpkgRoot = "C:\8.6\otserv_860\vcpkg"
$file = "$VcpkgRoot\scripts\cmake\vcpkg_find_acquire_program.cmake"
if (-not (Test-Path $file)) {
    Write-Warning "Nao encontrado: $file"
    return
}
$content = Get-Content $file -Raw
if ($content -match '_vcpkg_pkgconfig_path') {
    Write-Host "Ja corrigido: $file"
    return
}
$old = @'
        elseif(CMAKE_HOST_WIN32)
            if(NOT EXISTS "${PKGCONFIG}")
                set(VERSION 0.29.2-3)
                set(program_version git-9.0.0.6373.5be8fcd83-1)
                vcpkg_acquire_msys(
                    PKGCONFIG_ROOT
                    NO_DEFAULT_PACKAGES
                    DIRECT_PACKAGES
                        "https://repo.msys2.org/mingw/i686/mingw-w64-i686-pkg-config-${VERSION}-any.pkg.tar.zst"
                        0c086bf306b6a18988cc982b3c3828c4d922a1b60fd24e17c3bead4e296ee6de48ce148bc6f9214af98be6a86cb39c37003d2dcb6561800fdf7d0d1028cf73a4
                        "https://repo.msys2.org/mingw/i686/mingw-w64-i686-libwinpthread-${program_version}-any.pkg.tar.zst"
                        c89c27b5afe4cf5fdaaa354544f070c45ace5e9d2f2ebb4b956a148f61681f050e67976894e6f52e42e708dadbf730fee176ac9add3c9864c21249034c342810
                )
            endif()
            set("${program}" "${PKGCONFIG_ROOT}/mingw32/bin/pkg-config.exe" CACHE INTERNAL "")
            set("${program}" "${${program}}" PARENT_SCOPE)
            return()
'@
$new = @'
        elseif(CMAKE_HOST_WIN32)
            set(_vcpkg_pkgconfig_path "")
            foreach(_cand IN ITEMS
                "$ENV{PKG_CONFIG}"
                "C:/msys64/mingw64/bin/pkg-config.exe"
                "C:/msys64/usr/bin/pkg-config.exe"
                "C:/msys64/mingw32/bin/pkg-config.exe"
            )
                if(_cand AND EXISTS "${_cand}")
                    set(_vcpkg_pkgconfig_path "${_cand}")
                    break()
                endif()
            endforeach()
            if(_vcpkg_pkgconfig_path)
                set("${program}" "${_vcpkg_pkgconfig_path}" CACHE INTERNAL "")
                set("${program}" "${${program}}" PARENT_SCOPE)
                return()
            endif()
            if(NOT EXISTS "${PKGCONFIG}")
                set(VERSION 0.29.2-3)
                set(program_version git-9.0.0.6373.5be8fcd83-1)
                vcpkg_acquire_msys(
                    PKGCONFIG_ROOT
                    NO_DEFAULT_PACKAGES
                    DIRECT_PACKAGES
                        "https://repo.msys2.org/mingw/i686/mingw-w64-i686-pkg-config-${VERSION}-any.pkg.tar.zst"
                        0c086bf306b6a18988cc982b3c3828c4d922a1b60fd24e17c3bead4e296ee6de48ce148bc6f9214af98be6a86cb39c37003d2dcb6561800fdf7d0d1028cf73a4
                        "https://repo.msys2.org/mingw/i686/mingw-w64-i686-libwinpthread-${program_version}-any.pkg.tar.zst"
                        c89c27b5afe4cf5fdaaa354544f070c45ace5e9d2f2ebb4b956a148f61681f050e67976894e6f52e42e708dadbf730fee176ac9add3c9864c21249034c342810
                )
            endif()
            set("${program}" "${PKGCONFIG_ROOT}/mingw32/bin/pkg-config.exe" CACHE INTERNAL "")
            set("${program}" "${${program}}" PARENT_SCOPE)
            return()
'@
if ($content -notmatch [regex]::Escape($old.Trim())) {
    Write-Warning "Bloco PKGCONFIG nao encontrado (vcpkg ja alterado?)"
    return
}
$content = $content.Replace($old, $new)
Set-Content -Path $file -Value $content -NoNewline
Write-Host "Corrigido: $file"
