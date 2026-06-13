import CoreGraphics
import Foundation

enum ProfileCatalog {
    static let cameras: [CameraProfile] = [
        canonAE1,
        contaxT2,
        yashicaT4,
        olympusXA,
        hasselblad500,
        mamiyaRB67,
        pentax67,
        olympusPenF,
        lomoLCA,
        holga120N,
        dianaF,
        polaroidSX70,
        fujiNaturaClassica,
        disposableFlash,
        canonG2,
        sonyF707,
        miniDVGrab,
        sonyMavicaFD,
        gameBoyCamera,
        fxnR
    ]

    static let filmStocks: [FilmStock] = [
        portra400,
        ektar100,
        ultramax400,
        ektachromeE100,
        velvia50,
        provia100F,
        triX400,
        hp5Plus,
        delta3200,
        instantColor
    ]

    static let all: [FilmProfile] = cameras.map { camera in
        makeProfile(camera: camera, film: defaultFilm(for: camera))
    }

    static func defaultFilm(for camera: CameraProfile) -> FilmStock {
        switch camera.format {
        case .instant:
            return instantColor
        case .ccd:
            return digitalCCD
        case .toy:
            return ultramax400
        case .disposable:
            return ultramax400
        default:
            return portra400
        }
    }

    static func compatibleFilms(for camera: CameraProfile) -> [FilmStock] {
        let authored = authoredFilms(for: camera)
        if !authored.isEmpty { return authored }

        switch camera.format {
        case .instant:
            return [instantColor, triX400]
        case .ccd:
            return [digitalCCD]
        default:
            return filmStocks.filter { $0.family != .digitalSensor && $0.family != .instant }
        }
    }

    static func makeProfile(camera: CameraProfile, film: FilmStock) -> FilmProfile {
        let recipe: FilmRecipe
        switch film.behavior {
        case .composeWithCamera:
            recipe = RecipeComposer.combine(camera.recipe, film.recipe)
        case .completeProfile:
            recipe = film.recipe
        }
        return FilmProfile(
            id: "\(camera.id)-\(film.id)",
            displayName: "\(camera.displayName) / \(film.displayName)",
            tagline: "\(camera.format.rawValue) • \(film.family.rawValue)",
            description: "\(camera.description) Mode response: \(film.description)",
            cameraName: camera.displayName,
            filmName: film.displayName,
            accent: ProfileAccent(
                red: (camera.accent.red * 0.58) + (film.accent.red * 0.42),
                green: (camera.accent.green * 0.58) + (film.accent.green * 0.42),
                blue: (camera.accent.blue * 0.58) + (film.accent.blue * 0.42)
            ),
            recipe: recipe,
            defaultAdjustments: UserAdjustments(
                intensity: 1,
                exposure: 0,
                temperature: 0,
                tint: 0,
                grain: 1,
                bloom: 1,
                halation: 1,
                vignette: 1,
                fade: camera.format == .instant ? 0.12 : 0,
                softness: 1,
                dust: camera.format == .toy || camera.format == .disposable ? 1 : 0.65,
                borderEnabled: camera.recipe.border.style != .none
            )
        )
    }

    private static func authoredFilms(for camera: CameraProfile) -> [FilmStock] {
        switch camera.id {
        case canonAE1.id:
            return [
                authoredFilm(camera: camera, stock: portra400, suffix: "portra", name: "Portra 400 AE", tagline: "Warm SLR negative") {
                    $0.vignette.amount *= 0.75
                    $0.lens.sharpen += 0.08
                    $0.color.saturation *= 0.96
                    $0.tone.p4.y = 0.92
                },
                authoredFilm(camera: camera, stock: ultramax400, suffix: "gold-party", name: "Gold Party 400", tagline: "Consumer flash warmth") {
                    $0.color.temperature += 0.18
                    $0.color.redBias *= 1.04
                    $0.color.blueBias *= 0.9
                    $0.bloom.amount += 0.04
                    $0.grain.amount += 0.1
                    $0.output.lightLeak = 0.18
                },
                authoredFilm(camera: camera, stock: triX400, suffix: "trix-street", name: "Tri-X Street", tagline: "Classic mono SLR") {
                    $0.color.contrast *= 1.2
                    $0.grain.amount += 0.22
                    $0.tone.p0.y = 0.02
                    $0.tone.p3.y = 0.88
                },
                authoredFilm(camera: camera, stock: ektachromeE100, suffix: "e100-slide", name: "E100 Slide", tagline: "Clean projector colour") {
                    $0.color.saturation *= 1.16
                    $0.color.temperature -= 0.08
                    $0.tone.p4.y = 1
                    $0.tone.p0.y = 0
                }
            ]
        case contaxT2.id:
            return [
                authoredFilm(camera: camera, stock: portra400, suffix: "zeiss-portra", name: "Zeiss Portra", tagline: "Glossy compact skin") {
                    $0.lens.sharpen += 0.18
                    $0.color.contrast *= 1.08
                    $0.color.saturation *= 1.08
                    $0.bloom.amount += 0.04
                },
                authoredFilm(camera: camera, stock: ektar100, suffix: "travel-reds", name: "Travel Reds", tagline: "Crisp saturated compact") {
                    $0.lens.sharpen += 0.32
                    $0.color.redBias *= 1.09
                    $0.color.saturation *= 1.18
                    $0.tone.p0.y = 0
                },
                authoredFilm(camera: camera, stock: triX400, suffix: "flash-mono", name: "Flash Mono", tagline: "Hard compact B&W") {
                    $0.color.contrast *= 1.3
                    $0.lens.sharpen += 0.15
                    $0.output.flashFalloff = 0.35
                }
            ]
        case yashicaT4.id:
            return [
                authoredFilm(camera: camera, stock: ektar100, suffix: "tessar-pop", name: "Tessar Pop", tagline: "Sharp colour punch") {
                    $0.lens.sharpen += 0.42
                    $0.color.saturation *= 1.22
                    $0.color.contrast *= 1.1
                },
                authoredFilm(camera: camera, stock: portra400, suffix: "t4-daylight", name: "Daylight T*", tagline: "Clean compact daylight") {
                    $0.color.temperature -= 0.08
                    $0.lens.sharpen += 0.18
                    $0.tone.p4.y = 0.98
                },
                authoredFilm(camera: camera, stock: triX400, suffix: "t4-mono", name: "T* Mono", tagline: "Crisp pocket B&W") {
                    $0.color.contrast *= 1.34
                    $0.grain.amount += 0.18
                    $0.lens.sharpen += 0.24
                }
            ]
        case olympusXA.id:
            return [
                authoredFilm(camera: camera, stock: ultramax400, suffix: "xa-pocket-gold", name: "Pocket Gold", tagline: "Warm tiny rangefinder") {
                    $0.vignette.amount += 0.3
                    $0.lens.edgeSoftness += 0.22
                    $0.color.temperature += 0.16
                    $0.output.lightLeak = 0.12
                },
                authoredFilm(camera: camera, stock: hp5Plus, suffix: "xa-rain-mono", name: "Rain Mono", tagline: "Moody soft corners") {
                    $0.color.contrast *= 1.18
                    $0.vignette.amount += 0.28
                    $0.tone.p0.y += 0.03
                },
                authoredFilm(camera: camera, stock: ektachromeE100, suffix: "xa-blue-hour", name: "Blue Hour", tagline: "Cool pocket chrome") {
                    $0.color.temperature -= 0.26
                    $0.color.tint -= 0.08
                    $0.lens.edgeSoftness += 0.18
                    $0.tone.p0.y += 0.04
                }
            ]
        case hasselblad500.id:
            return [
                authoredFilm(camera: camera, stock: portra400, suffix: "square-portra", name: "Square Portra", tagline: "Calm studio negative") {
                    $0.grain.amount *= 0.72
                    $0.color.contrast *= 0.96
                },
                authoredFilm(camera: camera, stock: ektar100, suffix: "square-ekar", name: "Gallery Ektar", tagline: "Fine-grain colour square") {
                    $0.grain.amount *= 0.65
                    $0.lens.sharpen += 0.1
                },
                authoredFilm(camera: camera, stock: hp5Plus, suffix: "square-hp5", name: "HP5 Contact", tagline: "Soft medium-format mono") {
                    $0.grain.amount *= 0.78
                    $0.tone.p0.y += 0.02
                }
            ]
        case mamiyaRB67.id:
            return [
                authoredFilm(camera: camera, stock: portra400, suffix: "rb-portrait", name: "Portrait 400", tagline: "Creamy 6x7 skin") {
                    $0.color.temperature += 0.06
                    $0.bloom.amount += 0.02
                },
                authoredFilm(camera: camera, stock: ektar100, suffix: "rb-studio", name: "Studio Ektar", tagline: "Controlled vivid 6x7") {
                    $0.color.contrast *= 0.95
                    $0.grain.amount *= 0.7
                },
                authoredFilm(camera: camera, stock: triX400, suffix: "rb-trix", name: "Tri-X Portrait", tagline: "Large negative grit") {
                    $0.grain.amount *= 0.82
                    $0.tone.p3.y += 0.04
                }
            ]
        case pentax67.id:
            return [
                authoredFilm(camera: camera, stock: portra400, suffix: "105-portra", name: "105 Portrait", tagline: "Large-format glow") {
                    $0.bloom.amount += 0.06
                    $0.lens.softness += 0.04
                    $0.grain.amount *= 0.68
                },
                authoredFilm(camera: camera, stock: triX400, suffix: "105-trix", name: "Fashion Tri-X", tagline: "Sculpted mono pop") {
                    $0.color.contrast *= 1.12
                    $0.grain.amount *= 0.78
                },
                authoredFilm(camera: camera, stock: velvia50, suffix: "67-velvia", name: "Velvia Landscape", tagline: "Huge chrome colour") {
                    $0.color.saturation *= 1.08
                    $0.vignette.amount *= 0.65
                }
            ]
        case olympusPenF.id:
            return [
                authoredFilm(camera: camera, stock: ultramax400, suffix: "half-diary", name: "Half Diary", tagline: "Travel grain") {
                    $0.grain.amount += 0.18
                    $0.vignette.amount += 0.08
                },
                authoredFilm(camera: camera, stock: triX400, suffix: "half-trix", name: "Half Tri-X", tagline: "Tiny-frame mono") {
                    $0.grain.amount += 0.24
                    $0.color.contrast *= 1.08
                },
                authoredFilm(camera: camera, stock: provia100F, suffix: "half-provia", name: "Half Provia", tagline: "Sharp travel chrome") {
                    $0.color.saturation *= 1.06
                    $0.lens.sharpen += 0.08
                }
            ]
        case lomoLCA.id:
            return [
                authoredFilm(camera: camera, stock: ultramax400, suffix: "lomo-color", name: "LC-A Color 400", tagline: "Saturated vignette") {
                    $0.color.saturation *= 1.34
                    $0.color.contrast *= 1.12
                    $0.color.redBias *= 1.06
                    $0.vignette.amount += 0.55
                    $0.output.lightLeak = 0.2
                },
                authoredFilm(camera: camera, stock: velvia50, suffix: "xpro-slide", name: "X-Pro Slide", tagline: "Cross-processed punch") {
                    $0.color.temperature += 0.18
                    $0.color.tint += 0.1
                    $0.color.cyanShift -= 0.32
                    $0.color.yellowShift += 0.34
                    $0.color.saturation *= 1.24
                    $0.tone.p0.y += 0.07
                    $0.tone.p4.y = 0.91
                },
                authoredFilm(camera: camera, stock: ultramax400, suffix: "redscale", name: "Redscale", tagline: "Burnt orange experiment") {
                    $0.color.temperature += 0.64
                    $0.color.redBias *= 1.3
                    $0.color.greenBias *= 0.92
                    $0.color.blueBias *= 0.5
                    $0.color.saturation *= 1.16
                    $0.tone.p0.y += 0.08
                    $0.tone.p4.y = 0.82
                },
                authoredFilm(camera: camera, stock: ultramax400, suffix: "fisheye", name: "Fisheye Color", tagline: "Bulged lomo lens") {
                    $0.lens.fisheye = .diagonal(strength: 0.92, fieldOfView: 170, edgeDarkness: 0.75, edgeBlur: 0.24, chromaticEdge: 0.72)
                    $0.vignette.amount += 0.45
                    $0.aberration.amount += 0.35
                    $0.output.lightLeak = 0.18
                }
            ]
        case holga120N.id:
            return [
                authoredFilm(camera: camera, stock: ultramax400, suffix: "holga-color", name: "Plastic Color", tagline: "Dreamy toy 120") {
                    $0.lens.edgeSoftness += 0.28
                    $0.lens.softness += 0.1
                    $0.vignette.amount += 0.48
                    $0.color.saturation *= 0.92
                    $0.output.lightLeak = 0.32
                },
                authoredFilm(camera: camera, stock: triX400, suffix: "holga-mono", name: "Plastic Mono", tagline: "Soft square B&W") {
                    $0.grain.amount += 0.28
                    $0.vignette.amount += 0.42
                    $0.lens.softness += 0.16
                    $0.tone.p0.y += 0.04
                },
                authoredFilm(camera: camera, stock: ultramax400, suffix: "holga-leak", name: "Light Leak Color", tagline: "Warm rough toy") {
                    $0.halation.amount += 0.18
                    $0.bloom.amount += 0.16
                    $0.color.temperature += 0.28
                    $0.color.redBias *= 1.12
                    $0.output.lightLeak = 0.75
                },
                authoredFilm(camera: camera, stock: ultramax400, suffix: "holga-fisheye", name: "Fisheye Toy", tagline: "Rounded plastic bend") {
                    $0.lens.fisheye = .circular(cropped: true, strength: 0.95, fieldOfView: 170, imageCircle: 1.02, edgeDarkness: 0.95, edgeBlur: 0.48, chromaticEdge: 0.7)
                    $0.vignette.amount += 0.5
                    $0.output.lightLeak = 0.28
                }
            ]
        case dianaF.id:
            return [
                authoredFilm(camera: camera, stock: ultramax400, suffix: "diana-dream", name: "Dream Color", tagline: "Soft low-fi colour") {
                    $0.bloom.amount += 0.22
                    $0.lens.softness += 0.28
                    $0.color.saturation *= 0.76
                    $0.color.tint += 0.12
                },
                authoredFilm(camera: camera, stock: ektachromeE100, suffix: "diana-xpro", name: "Purple X-Pro", tagline: "Surreal slide cast") {
                    $0.color.tint += 0.32
                    $0.color.blueBias *= 1.26
                    $0.color.redBias *= 1.1
                    $0.color.saturation *= 1.18
                    $0.vignette.amount += 0.42
                    $0.output.lightLeak = 0.22
                },
                authoredFilm(camera: camera, stock: ultramax400, suffix: "diana-fisheye", name: "Fisheye Dream", tagline: "Soft bent edges") {
                    $0.lens.fisheye = .circular(cropped: false, strength: 0.9, fieldOfView: 170, imageCircle: 0.92, edgeDarkness: 1.05, edgeBlur: 0.55, chromaticEdge: 0.78)
                    $0.bloom.amount += 0.2
                    $0.color.saturation *= 0.84
                }
            ]
        case polaroidSX70.id:
            return [
                authoredFilm(camera: camera, stock: instantColor, suffix: "sx70-color", name: "SX-70 Color", tagline: "Slow warm instant") {
                    $0.color.temperature += 0.12
                    $0.tone.p0.y += 0.04
                    $0.output.aspect = .instant
                },
                authoredFilm(camera: camera, stock: instantColor, suffix: "sx70-expired", name: "Expired SX-70", tagline: "Faded chemistry") {
                    $0.color.saturation *= 0.78
                    $0.tone.p0.y += 0.08
                    $0.dust.amount += 0.04
                    $0.output.aspect = .instant
                },
                authoredFilm(camera: camera, stock: triX400, suffix: "sx70-bw", name: "SX-70 B&W", tagline: "Soft instant mono") {
                    $0.color.monochrome = true
                    $0.color.saturation = 0
                    $0.border.style = .instant
                    $0.output.aspect = .instant
                }
            ]
        case fujiNaturaClassica.id:
            return [
                authoredFilm(camera: camera, stock: ultramax400, suffix: "natura-1600", name: "Natura 1600 Night", tagline: "No-flash low light") {
                    $0.color.temperature -= 0.04
                    $0.grain.amount += 0.24
                    $0.tone.p0.y += 0.04
                },
                authoredFilm(camera: camera, stock: portra400, suffix: "press-800-push", name: "Press 800 Push", tagline: "Warm available light") {
                    $0.color.temperature += 0.08
                    $0.grain.amount += 0.22
                    $0.bloom.amount += 0.06
                },
                authoredFilm(camera: camera, stock: ektachromeE100, suffix: "fluorescent", name: "Fluorescent Shop", tagline: "Green-blue interior cast") {
                    $0.color.temperature -= 0.18
                    $0.color.greenBias *= 1.08
                    $0.color.tint -= 0.12
                }
            ]
        case disposableFlash.id:
            return [
                authoredFilm(camera: camera, stock: ultramax400, suffix: "flash-party", name: "Flash Party", tagline: "Hard disposable flash") {
                    $0.color.exposure += 0.2
                    $0.color.contrast *= 1.12
                    $0.vignette.amount += 0.22
                    $0.output.flashFalloff = 0.95
                    $0.output.lightLeak = 0.16
                    $0.output.dateStamp = true
                },
                authoredFilm(camera: camera, stock: ultramax400, suffix: "beach-day", name: "Beach Day", tagline: "Cheap sun colour") {
                    $0.color.saturation *= 1.28
                    $0.color.temperature += 0.2
                    $0.tone.p4.y = 0.94
                    $0.output.lightLeak = 0.22
                    $0.output.dateStamp = true
                },
                authoredFilm(camera: camera, stock: triX400, suffix: "flash-mono", name: "Flash Mono", tagline: "Point-blank B&W") {
                    $0.color.contrast *= 1.42
                    $0.grain.amount += 0.3
                    $0.output.flashFalloff = 1.0
                    $0.output.dateStamp = true
                },
                authoredFilm(camera: camera, stock: ultramax400, suffix: "fisheye-flash", name: "Fisheye Flash", tagline: "Skate mag bend") {
                    $0.lens.fisheye = .diagonal(strength: 0.98, fieldOfView: 175, edgeDarkness: 0.8, edgeBlur: 0.28, chromaticEdge: 0.86)
                    $0.vignette.amount += 0.35
                    $0.output.flashFalloff = 0.95
                    $0.output.lightLeak = 0.2
                    $0.output.dateStamp = true
                }
            ]
        case canonG2.id:
            return [
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "warm-jpeg", name: "Warm JPEG", tagline: "Early compact colour") {
                    $0.color.temperature += 0.18
                    $0.color.contrast *= 1.12
                    $0.lens.sharpen += 0.28
                    $0.output.jpegCrunch = 0.34
                    $0.output.chromaBleed = 0.18
                },
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "office-flash", name: "Office Flash", tagline: "Brittle indoor CCD") {
                    $0.color.exposure += 0.2
                    $0.color.temperature -= 0.08
                    $0.color.tint -= 0.12
                    $0.bloom.amount += 0.08
                    $0.output.flashFalloff = 0.42
                    $0.output.jpegCrunch = 0.42
                    $0.output.chromaBleed = 0.26
                },
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "low-res", name: "Low-res Web", tagline: "Downsampled upload") {
                    $0.lens.downsample = 0.36
                    $0.lens.sharpen += 0.7
                    $0.color.saturation *= 0.86
                    $0.output.jpegCrunch = 0.82
                    $0.output.chromaBleed = 0.34
                }
            ]
        case sonyF707.id:
            return [
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "cyber-vivid", name: "Cyber Vivid", tagline: "Saturated CCD reds") {
                    $0.color.saturation *= 1.38
                    $0.color.redBias *= 1.12
                    $0.color.blueBias *= 1.08
                    $0.aberration.amount += 0.55
                    $0.output.jpegCrunch = 0.28
                    $0.output.chromaBleed = 0.26
                },
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "purple-fringe", name: "Purple Fringe", tagline: "Hard highlight edges") {
                    $0.color.tint += 0.2
                    $0.color.contrast *= 1.16
                    $0.aberration.amount += 1.05
                    $0.output.jpegCrunch = 0.32
                    $0.output.chromaBleed = 0.48
                }
            ]
        case miniDVGrab.id:
            return [
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "tape-still", name: "Tape Still", tagline: "Video frame grab") {
                    $0.lens.downsample = 0.32
                    $0.color.contrast *= 1.26
                    $0.color.saturation *= 1.22
                    $0.output.jpegCrunch = 0.7
                    $0.output.chromaBleed = 0.64
                    $0.output.scanlines = 0.58
                },
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "night-tape", name: "Night Tape", tagline: "Blue noisy camcorder") {
                    $0.color.temperature -= 0.38
                    $0.color.tint -= 0.12
                    $0.grain.amount += 0.42
                    $0.bloom.amount += 0.12
                    $0.output.jpegCrunch = 0.78
                    $0.output.chromaBleed = 0.72
                    $0.output.scanlines = 0.74
                }
            ]
        case sonyMavicaFD.id:
            return [
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "floppy-640", name: "Floppy 640", tagline: "JPEG smear") {
                    $0.lens.downsample = 0.2
                    $0.lens.sharpen += 0.9
                    $0.output.jpegCrunch = 1.0
                    $0.output.chromaBleed = 0.38
                    $0.color.saturation *= 0.82
                },
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "fine-mode", name: "Fine Mode", tagline: "Chunky early digital") {
                    $0.lens.downsample = 0.28
                    $0.color.saturation *= 0.88
                    $0.color.contrast *= 1.18
                    $0.output.jpegCrunch = 0.72
                    $0.output.chromaBleed = 0.28
                }
            ]
        case gameBoyCamera.id:
            return [
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "dmg-green", name: "DMG Green", tagline: "Four-tone green") {
                    $0.color.monochrome = true
                    $0.color.temperature += 0.3
                    $0.lens.downsample = 0.18
                    $0.lens.sharpen += 0.9
                    $0.border.style = .thin
                    $0.output.palette = .gameBoyGreen
                    $0.output.posterizeLevels = 4
                },
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "pocket-mono", name: "Pocket Mono", tagline: "Harsh dither B&W") {
                    $0.color.monochrome = true
                    $0.color.contrast *= 1.5
                    $0.lens.downsample = 0.16
                    $0.output.palette = .hardMono
                    $0.output.posterizeLevels = 4
                },
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "thermal-print", name: "Thermal Print", tagline: "Washed tiny print") {
                    $0.color.monochrome = true
                    $0.tone.p0.y += 0.16
                    $0.tone.p4.y = 0.82
                    $0.lens.downsample = 0.14
                    $0.output.palette = .thermal
                    $0.output.posterizeLevels = 5
                }
            ]
        case fxnR.id:
            return [
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "amber-cafe", name: "Amber Cafe", tagline: "Warm FXN interior") {
                    $0.color.temperature += 0.62
                    $0.color.redBias *= 1.16
                    $0.color.greenBias *= 0.98
                    $0.color.blueBias *= 0.72
                    $0.color.yellowShift += 0.28
                    $0.color.cyanShift -= 0.18
                    $0.bloom.amount += 0.16
                    $0.halation.amount += 0.1
                    $0.tone.p0.y += 0.08
                    $0.output.jpegCrunch = 0.32
                    $0.output.chromaBleed = 0.24
                    $0.output.labControlsEnabled = false
                },
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "flash-wood", name: "Flash Wood", tagline: "Bright warm flash") {
                    $0.color.exposure += 0.28
                    $0.color.temperature += 0.52
                    $0.color.redBias *= 1.12
                    $0.halation.amount += 0.14
                    $0.output.flashFalloff = 0.68
                    $0.output.jpegCrunch = 0.38
                    $0.output.chromaBleed = 0.28
                },
                authoredFilm(camera: camera, stock: digitalCCD, suffix: "urban-night", name: "Urban Night", tagline: "Soft neon amber") {
                    $0.color.temperature += 0.3
                    $0.color.tint += 0.08
                    $0.color.contrast *= 1.22
                    $0.color.saturation *= 1.22
                    $0.grain.amount += 0.32
                    $0.bloom.amount += 0.22
                    $0.tone.p0.y += 0.06
                    $0.output.jpegCrunch = 0.42
                    $0.output.chromaBleed = 0.36
                }
            ]
        default:
            return []
        }
    }

    // MARK: Cameras

    static let canonAE1 = CameraProfile(
        id: "canon-ae1-reference",
        displayName: "Canon AE-1",
        reference: "Classic late-1970s 35mm SLR archetype",
        format: .thirtyFive,
        tagline: "Clean 135 SLR baseline",
        description: "A controlled 35mm SLR body with moderate optical contrast, natural sharpness, and restrained falloff.",
        accent: ProfileAccent(red: 0.78, green: 0.72, blue: 0.64),
        recipe: cameraRecipe(
            color: color(exposure: 0, contrast: 1.03, saturation: 1, temperature: 0.02, red: 1, green: 1, blue: 1),
            tone: curve(0.01, 0.23, 0.5, 0.78, 0.98),
            bloom: 0.02,
            halation: 0.04,
            vignette: 0.18,
            lens: LensRecipe(softness: 0.02, edgeSoftness: 0.03, sharpen: 0.14, downsample: 1),
            aberration: 0.08,
            border: .none
        )
    )

    static let contaxT2 = CameraProfile(
        id: "contax-t2-reference",
        displayName: "Contax T2",
        reference: "Premium compact 35mm, Zeiss 38mm compact look",
        format: .thirtyFive,
        tagline: "Sharp luxury compact",
        description: "Compact 35mm rendering with crisp central detail, punchy microcontrast, and mild flash-era edge falloff.",
        accent: ProfileAccent(red: 0.68, green: 0.72, blue: 0.78),
        recipe: cameraRecipe(
            color: color(exposure: 0.02, contrast: 1.08, saturation: 1.02, temperature: 0.03, red: 1.01, green: 1, blue: 0.99),
            tone: curve(0.0, 0.2, 0.51, 0.82, 0.99),
            bloom: 0.04,
            halation: 0.04,
            vignette: 0.28,
            lens: LensRecipe(softness: 0, edgeSoftness: 0.04, sharpen: 0.42, downsample: 1),
            aberration: 0.12,
            border: .none
        )
    )

    static let yashicaT4 = CameraProfile(
        id: "yashica-t4-reference",
        displayName: "Yashica T4",
        reference: "Carl Zeiss Tessar T* 35mm compact archetype",
        format: .thirtyFive,
        tagline: "Tessar pocket snap",
        description: "A sharp 35mm compact look with hard microcontrast, clean center detail, and glossy point-and-shoot colour.",
        accent: ProfileAccent(red: 0.62, green: 0.72, blue: 0.84),
        recipe: cameraRecipe(
            color: color(exposure: 0.01, contrast: 1.12, saturation: 1.04, temperature: 0, tint: 0.01, red: 1.01, green: 1.01, blue: 1),
            tone: curve(0, 0.18, 0.5, 0.84, 0.99),
            bloom: 0.03,
            halation: 0.03,
            vignette: 0.24,
            lens: LensRecipe(softness: 0, edgeSoftness: 0.05, sharpen: 0.55, downsample: 1),
            aberration: 0.16,
            border: .none
        )
    )

    static let olympusXA = CameraProfile(
        id: "olympus-xa-reference",
        displayName: "Olympus XA",
        reference: "Pocket 35mm rangefinder / Zuiko compact archetype",
        format: .thirtyFive,
        tagline: "Pocket rangefinder mood",
        description: "Tiny 35mm rangefinder behavior with intimate contrast, visible corner falloff, and soft pocket-camera edges.",
        accent: ProfileAccent(red: 0.72, green: 0.62, blue: 0.52),
        recipe: cameraRecipe(
            color: color(exposure: -0.01, contrast: 1.02, saturation: 0.98, temperature: 0.03, tint: -0.01, red: 1.01, green: 1, blue: 0.98),
            tone: curve(0.03, 0.23, 0.5, 0.78, 0.96),
            bloom: 0.02,
            halation: 0.03,
            vignette: 0.42,
            lens: LensRecipe(softness: 0.05, edgeSoftness: 0.22, sharpen: 0.08, downsample: 0.98),
            aberration: 0.18,
            border: .none
        )
    )

    static let hasselblad500 = CameraProfile(
        id: "hasselblad-500-reference",
        displayName: "Hasselblad 500",
        reference: "120 6x6 medium-format studio/travel archetype",
        format: .medium120,
        tagline: "Square medium-format clarity",
        description: "Large negative feel with smoother tonal transitions, lower apparent grain, square-frame calm, and refined edge behavior.",
        accent: ProfileAccent(red: 0.62, green: 0.72, blue: 0.76),
        recipe: cameraRecipe(
            color: color(exposure: 0.03, contrast: 0.96, saturation: 1.02, temperature: 0, red: 1, green: 1.01, blue: 1.01),
            tone: curve(0.03, 0.25, 0.52, 0.78, 0.96),
            grain: GrainRecipe(amount: -0.1, scale: -0.25, monochrome: true, shadows: 0, highlights: 0),
            bloom: 0.02,
            halation: 0.04,
            vignette: 0.08,
            lens: LensRecipe(softness: 0, edgeSoftness: 0.01, sharpen: 0.22, downsample: 1),
            aberration: 0.02,
            border: .print
        )
    )

    static let mamiyaRB67 = CameraProfile(
        id: "mamiya-rb67-reference",
        displayName: "Mamiya RB67",
        reference: "120 6x7 medium-format portrait/studio archetype",
        format: .medium120,
        tagline: "Creamy 6x7 portrait negative",
        description: "Medium-format body profile with gentle contrast, creamy highlight transition, and reduced apparent grain.",
        accent: ProfileAccent(red: 0.78, green: 0.66, blue: 0.58),
        recipe: cameraRecipe(
            color: color(exposure: 0.04, brightness: 0.01, contrast: 0.94, saturation: 0.99, temperature: 0.05, red: 1.02, green: 1, blue: 0.98),
            tone: curve(0.04, 0.27, 0.52, 0.77, 0.94),
            grain: GrainRecipe(amount: -0.08, scale: -0.18, monochrome: true, shadows: 0, highlights: 0),
            bloom: 0.03,
            halation: 0.05,
            vignette: 0.12,
            lens: LensRecipe(softness: 0.03, edgeSoftness: 0.02, sharpen: 0.1, downsample: 1),
            aberration: 0.03,
            border: .print
        )
    )

    static let pentax67 = CameraProfile(
        id: "pentax-67-reference",
        displayName: "Pentax 67",
        reference: "6x7 medium-format SLR / 105mm portrait archetype",
        format: .medium120,
        tagline: "Huge 6x7 portrait glow",
        description: "Big negative rendering with smooth tonal separation, creamy highlights, subtle falloff, and larger-than-35mm calm.",
        accent: ProfileAccent(red: 0.76, green: 0.64, blue: 0.56),
        recipe: cameraRecipe(
            color: color(exposure: 0.04, brightness: 0.01, contrast: 0.95, saturation: 1.01, temperature: 0.04, tint: 0, red: 1.01, green: 1, blue: 0.99),
            tone: curve(0.04, 0.27, 0.52, 0.77, 0.95),
            grain: GrainRecipe(amount: -0.12, scale: -0.25, monochrome: true, shadows: 0, highlights: 0),
            bloom: 0.05,
            halation: 0.05,
            vignette: 0.14,
            lens: LensRecipe(softness: 0.04, edgeSoftness: 0.03, sharpen: 0.12, downsample: 1),
            aberration: 0.03,
            border: .print
        )
    )

    static let olympusPenF = CameraProfile(
        id: "olympus-pen-f-reference",
        displayName: "Olympus Pen F",
        reference: "35mm half-frame 18x24mm vertical SLR archetype",
        format: .halfFrame,
        tagline: "Half-frame travel diary",
        description: "Half-frame rendering with more visible grain, light compact-camera softness, and diary-like framing.",
        accent: ProfileAccent(red: 0.82, green: 0.74, blue: 0.58),
        recipe: cameraRecipe(
            color: color(exposure: 0.02, contrast: 1.02, saturation: 0.98, temperature: 0.06, red: 1.01, green: 1, blue: 0.97),
            tone: curve(0.03, 0.24, 0.5, 0.77, 0.95),
            grain: GrainRecipe(amount: 0.12, scale: 0.18, monochrome: true, shadows: 0.08, highlights: 0.04),
            bloom: 0.03,
            halation: 0.03,
            vignette: 0.36,
            lens: LensRecipe(softness: 0.08, edgeSoftness: 0.18, sharpen: 0.05, downsample: 0.96),
            aberration: 0.15,
            border: .halfFrame
        )
    )

    static let lomoLCA = CameraProfile(
        id: "lomo-lca-reference",
        displayName: "Lomo LC-A",
        reference: "Soviet compact / Lomographic saturation-vignette archetype",
        format: .thirtyFive,
        tagline: "Saturated vignette snap",
        description: "Compact Lomographic style with heavy corner density, punchy colour, imperfect exposure, and high-energy contrast.",
        accent: ProfileAccent(red: 0.95, green: 0.35, blue: 0.28),
        recipe: cameraRecipe(
            color: color(exposure: -0.04, brightness: 0.01, contrast: 1.16, saturation: 1.18, temperature: 0.08, tint: 0.03, red: 1.05, green: 0.98, blue: 0.98),
            tone: curve(0.02, 0.16, 0.5, 0.84, 0.96),
            bloom: 0.06,
            halation: 0.06,
            vignette: 0.92,
            lens: LensRecipe(softness: 0.07, edgeSoftness: 0.26, sharpen: 0.04, downsample: 0.96),
            aberration: 0.32,
            dust: 0.04,
            border: .thin
        )
    )

    static let holga120N = CameraProfile(
        id: "holga-120n-reference",
        displayName: "Holga 120N",
        reference: "120 plastic-lens toy camera archetype",
        format: .toy,
        tagline: "Plastic 120 vignettes",
        description: "Soft plastic lens, strong corner darkening, uneven contrast, possible light-leak energy, and medium-format roughness.",
        accent: ProfileAccent(red: 0.92, green: 0.42, blue: 0.34),
        recipe: cameraRecipe(
            color: color(exposure: 0.04, brightness: 0.01, contrast: 1.1, saturation: 1.06, temperature: 0.1, tint: 0.04, red: 1.04, green: 0.98, blue: 0.94),
            tone: curve(0.02, 0.18, 0.52, 0.78, 0.94),
            bloom: 0.07,
            halation: 0.08,
            vignette: 1.2,
            lens: LensRecipe(softness: 0.28, edgeSoftness: 0.55, sharpen: 0, downsample: 0.9),
            aberration: 0.5,
            dust: 0.08,
            border: .thin
        )
    )

    static let dianaF = CameraProfile(
        id: "diana-f-reference",
        displayName: "Diana F+",
        reference: "Lo-fi 120 plastic camera / soft-focus archetype",
        format: .toy,
        tagline: "Dreamy low-fi blur",
        description: "Lower saturation, soft surreal blur, heavy vignette, and unpredictable plastic-lens color.",
        accent: ProfileAccent(red: 0.58, green: 0.48, blue: 0.92),
        recipe: cameraRecipe(
            color: color(exposure: 0.05, brightness: 0.02, contrast: 0.94, saturation: 0.86, temperature: 0.05, tint: 0.12, red: 1.02, green: 0.96, blue: 1.08),
            tone: curve(0.06, 0.26, 0.51, 0.73, 0.91),
            bloom: 0.1,
            halation: 0.08,
            vignette: 1.35,
            lens: LensRecipe(softness: 0.34, edgeSoftness: 0.68, sharpen: 0, downsample: 0.86),
            aberration: 0.65,
            dust: 0.06,
            border: .thin
        )
    )

    static let polaroidSX70 = CameraProfile(
        id: "polaroid-sx70-reference",
        displayName: "Polaroid SX-70",
        reference: "Classic folding instant SLR archetype",
        format: .instant,
        tagline: "Slow instant chemistry",
        description: "Low-speed instant-camera behavior with warm chemistry, bright natural-light bias, creamy highlights, and white-frame presentation.",
        accent: ProfileAccent(red: 0.95, green: 0.82, blue: 0.58),
        recipe: cameraRecipe(
            color: color(exposure: 0.08, brightness: 0.03, contrast: 0.9, saturation: 0.92, temperature: 0.22, tint: 0.04, red: 1.05, green: 1.01, blue: 0.94),
            tone: curve(0.1, 0.3, 0.54, 0.78, 0.93),
            bloom: 0.16,
            halation: 0.16,
            vignette: 0.18,
            lens: LensRecipe(softness: 0.18, edgeSoftness: 0.14, sharpen: 0, downsample: 0.95),
            aberration: 0.04,
            dust: 0.03,
            border: .instant
        )
    )

    static let fujiNaturaClassica = CameraProfile(
        id: "fuji-natura-classica-reference",
        displayName: "Fuji Natura Classica",
        reference: "Low-light 35mm compact / Natura 1600 archetype",
        format: .thirtyFive,
        tagline: "No-flash night colour",
        description: "Low-light compact behavior with available-light warmth, high-speed grain, subdued flash use, and indoor colour casts.",
        accent: ProfileAccent(red: 0.44, green: 0.72, blue: 0.56),
        recipe: cameraRecipe(
            color: color(exposure: 0.08, brightness: 0.02, contrast: 0.96, saturation: 0.98, temperature: 0.02, tint: -0.03, red: 1.01, green: 1.02, blue: 0.99),
            tone: curve(0.06, 0.27, 0.52, 0.78, 0.94),
            grain: GrainRecipe(amount: 0.18, scale: 0.3, monochrome: false, shadows: 0.25, highlights: 0.12),
            bloom: 0.07,
            halation: 0.04,
            vignette: 0.22,
            lens: LensRecipe(softness: 0.04, edgeSoftness: 0.08, sharpen: 0.08, downsample: 0.97),
            aberration: 0.12,
            border: .none
        )
    )

    static let disposableFlash = CameraProfile(
        id: "disposable-flash-reference",
        displayName: "Disposable Flash",
        reference: "Single-use 35mm fixed-focus flash camera archetype",
        format: .disposable,
        tagline: "Cheap flash and rough plastic",
        description: "Fixed-focus plastic optics, flash-forward contrast, rough corners, coarse grain emphasis, and imperfect color.",
        accent: ProfileAccent(red: 0.98, green: 0.76, blue: 0.22),
        recipe: cameraRecipe(
            color: color(exposure: 0.18, brightness: 0.02, contrast: 1.18, saturation: 1.12, temperature: 0.18, tint: -0.02, red: 1.05, green: 1, blue: 0.92),
            tone: curve(0.0, 0.17, 0.5, 0.86, 1),
            grain: GrainRecipe(amount: 0.12, scale: 0.25, monochrome: false, shadows: 0.12, highlights: 0.05),
            bloom: 0.1,
            halation: 0.1,
            vignette: 0.82,
            lens: LensRecipe(softness: 0.12, edgeSoftness: 0.32, sharpen: 0.02, downsample: 0.92),
            aberration: 0.28,
            dust: 0.08,
            border: .thin
        )
    )

    static let canonG2 = CameraProfile(
        id: "canon-powershot-g2-reference",
        displayName: "Canon PowerShot G2",
        reference: "2001 4MP CCD prosumer compact archetype",
        format: .ccd,
        tagline: "Warm early CCD compact",
        description: "Early CCD compact color with good balance, brittle highlights, JPEG-era sharpness, and low-resolution texture.",
        accent: ProfileAccent(red: 0.56, green: 0.68, blue: 0.92),
        recipe: cameraRecipe(
            color: color(exposure: 0.02, contrast: 1.2, saturation: 1.05, temperature: 0.04, tint: -0.04, red: 1.02, green: 1.02, blue: 0.98),
            tone: curve(0, 0.16, 0.5, 0.88, 0.97),
            grain: GrainRecipe(amount: 0.36, scale: 0.95, monochrome: false, shadows: 0.9, highlights: 0.8),
            bloom: 0.03,
            halation: 0.01,
            vignette: 0.18,
            lens: LensRecipe(softness: 0, edgeSoftness: 0, sharpen: 0.85, downsample: 0.62),
            aberration: 0.45,
            border: .none
        )
    )

    static let sonyF707 = CameraProfile(
        id: "sony-f707-reference",
        displayName: "Sony DSC-F707",
        reference: "2001 5MP CCD Cyber-shot archetype",
        format: .ccd,
        tagline: "Vivid CCD purple edges",
        description: "Vivid early-2000s CCD output with crisp detail, purple/cyan fringing, limited dynamic range, and saturated reds.",
        accent: ProfileAccent(red: 0.42, green: 0.56, blue: 1),
        recipe: cameraRecipe(
            color: color(exposure: 0.03, contrast: 1.24, saturation: 1.16, temperature: -0.05, tint: 0.05, red: 1.05, green: 1, blue: 1.08),
            tone: curve(0, 0.14, 0.51, 0.9, 0.98),
            grain: GrainRecipe(amount: 0.42, scale: 1.05, monochrome: false, shadows: 0.9, highlights: 0.85),
            bloom: 0.04,
            halation: 0.01,
            vignette: 0.12,
            lens: LensRecipe(softness: 0, edgeSoftness: 0, sharpen: 1.0, downsample: 0.64),
            aberration: 1.1,
            border: .none
        )
    )

    static let miniDVGrab = CameraProfile(
        id: "mini-dv-grab-reference",
        displayName: "Mini DV Still",
        reference: "Y2K video still / camcorder frame-grab archetype",
        format: .ccd,
        tagline: "Tape-era digital still",
        description: "Low-resolution video-still character with clipped colors, digital sharpness, chroma noise, and compact dynamic range.",
        accent: ProfileAccent(red: 0.66, green: 0.7, blue: 1),
        recipe: cameraRecipe(
            color: color(exposure: 0.02, contrast: 1.28, saturation: 1.18, temperature: -0.12, tint: -0.04, red: 0.98, green: 1.02, blue: 1.08),
            tone: curve(0, 0.13, 0.52, 0.91, 1),
            grain: GrainRecipe(amount: 0.5, scale: 0.9, monochrome: false, shadows: 0.9, highlights: 0.85),
            bloom: 0.04,
            halation: 0,
            vignette: 0.1,
            lens: LensRecipe(softness: 0, edgeSoftness: 0, sharpen: 1.25, downsample: 0.45),
            aberration: 0.75,
            border: .none
        )
    )

    static let sonyMavicaFD = CameraProfile(
        id: "sony-mavica-fd-reference",
        displayName: "Sony Mavica FD",
        reference: "Floppy-disk early digital still camera archetype",
        format: .ccd,
        tagline: "Floppy JPEG digital",
        description: "Low-resolution floppy-camera output with visible JPEG-era crunch, clipped highlights, and smeared early digital colour.",
        accent: ProfileAccent(red: 0.38, green: 0.52, blue: 0.82),
        recipe: cameraRecipe(
            color: color(exposure: 0.01, contrast: 1.18, saturation: 0.92, temperature: -0.04, tint: -0.02, red: 0.98, green: 1.02, blue: 1.04),
            tone: curve(0, 0.15, 0.5, 0.88, 0.96),
            grain: GrainRecipe(amount: 0.55, scale: 0.8, monochrome: false, shadows: 0.9, highlights: 0.8),
            bloom: 0.02,
            halation: 0,
            vignette: 0.08,
            lens: LensRecipe(softness: 0, edgeSoftness: 0.02, sharpen: 1.25, downsample: 0.3),
            aberration: 0.35,
            border: .none
        )
    )

    static let gameBoyCamera = CameraProfile(
        id: "game-boy-camera-reference",
        displayName: "Game Boy Camera",
        reference: "Four-tone low-resolution toy digital camera archetype",
        format: .ccd,
        tagline: "Tiny dither toycam",
        description: "Extremely low-resolution monochrome toy-camera behavior with hard contrast, posterized tones, and printer-like texture.",
        accent: ProfileAccent(red: 0.54, green: 0.78, blue: 0.38),
        recipe: cameraRecipe(
            color: color(exposure: 0.02, contrast: 1.5, saturation: 0, temperature: 0.18, tint: -0.04, red: 0.92, green: 1.08, blue: 0.82),
            tone: curve(0.12, 0.2, 0.48, 0.72, 0.88),
            grain: GrainRecipe(amount: 0.34, scale: 0.6, monochrome: true, shadows: 0.8, highlights: 0.65),
            bloom: 0,
            halation: 0,
            vignette: 0.05,
            lens: LensRecipe(softness: 0, edgeSoftness: 0, sharpen: 1.6, downsample: 0.16),
            aberration: 0,
            border: .thin
        )
    )

    static let fxnR = CameraProfile(
        id: "fxn-r-inspired-reference",
        displayName: "FXN R",
        reference: "Dazz-style FXN R inspired warm digital profile",
        format: .ccd,
        tagline: "Amber app-camera night",
        description: "A warm R-series app-camera style with amber interiors, soft flash, lifted blacks, and glossy urban-night colour.",
        accent: ProfileAccent(red: 0.98, green: 0.62, blue: 0.28),
        recipe: cameraRecipe(
            color: color(exposure: 0.06, brightness: 0.02, contrast: 1.08, saturation: 1.08, temperature: 0.28, tint: 0.04, red: 1.08, green: 0.99, blue: 0.88),
            tone: curve(0.06, 0.25, 0.52, 0.82, 0.96),
            grain: GrainRecipe(amount: 0.32, scale: 0.95, monochrome: false, shadows: 0.75, highlights: 0.5),
            bloom: 0.08,
            halation: 0.08,
            vignette: 0.2,
            lens: LensRecipe(softness: 0.06, edgeSoftness: 0.08, sharpen: 0.35, downsample: 0.72),
            aberration: 0.2,
            border: .none
        )
    )

    // MARK: Film stocks

    static let portra400 = FilmStock(
        id: "portra-400-response",
        displayName: "Portra 400",
        reference: "Professional ISO 400 color negative response",
        family: .colorNegative,
        tagline: "Skin tone latitude",
        description: "Fine high-speed grain, forgiving negative latitude, warm skin response, and soft highlight shoulder.",
        accent: ProfileAccent(red: 0.96, green: 0.66, blue: 0.44),
        recipe: filmRecipe(
            color: color(exposure: 0.04, brightness: 0.01, contrast: 0.98, saturation: 1.05, temperature: 0.18, tint: 0.03, red: 1.04, green: 1.01, blue: 0.95, highlight: (0.28, 0.16, 0.04), shadow: (0.02, 0.03, 0.08), cmy: (-0.12, -0.04, 0.1)),
            tone: curve(0.05, 0.25, 0.51, 0.78, 0.94),
            grain: GrainRecipe(amount: 0.34, scale: 1.08, monochrome: true, shadows: 0.55, highlights: 0.32),
            bloom: 0.04,
            halation: 0.08,
            vignette: 0.04
        )
    )

    static let ektar100 = FilmStock(
        id: "ektar-100-response",
        displayName: "Ektar 100",
        reference: "Ultra-vivid ISO 100 color negative response",
        family: .colorNegative,
        tagline: "Ultra-vivid fine grain",
        description: "Very fine grain, vivid saturation, crisp color separation, stronger blues/reds, and tighter exposure feel.",
        accent: ProfileAccent(red: 0.92, green: 0.32, blue: 0.26),
        recipe: filmRecipe(
            color: color(exposure: -0.02, contrast: 1.14, saturation: 1.28, temperature: 0.04, tint: 0.02, red: 1.06, green: 1.03, blue: 1.05, highlight: (0.12, 0.08, 0.02), shadow: (-0.02, 0.02, 0.1), cmy: (-0.18, -0.08, -0.04)),
            tone: curve(0.01, 0.18, 0.5, 0.84, 0.98),
            grain: GrainRecipe(amount: 0.16, scale: 0.75, monochrome: true, shadows: 0.35, highlights: 0.18),
            bloom: 0.02,
            halation: 0.04,
            vignette: 0.02
        )
    )

    static let ultramax400 = FilmStock(
        id: "consumer-400-response",
        displayName: "Consumer 400",
        reference: "Consumer ISO 400 color negative response",
        family: .colorNegative,
        tagline: "Everyday drugstore color",
        description: "Warm consumer color, stronger grain, lively reds/yellows, and less polished latitude.",
        accent: ProfileAccent(red: 0.98, green: 0.78, blue: 0.24),
        recipe: filmRecipe(
            color: color(exposure: 0.06, contrast: 1.08, saturation: 1.15, temperature: 0.24, tint: -0.02, red: 1.06, green: 1.01, blue: 0.91, highlight: (0.26, 0.16, 0.02), shadow: (0.04, 0.02, -0.02), cmy: (-0.06, -0.03, 0.18)),
            tone: curve(0.02, 0.2, 0.5, 0.82, 0.97),
            grain: GrainRecipe(amount: 0.52, scale: 1.45, monochrome: false, shadows: 0.82, highlights: 0.42),
            bloom: 0.06,
            halation: 0.08,
            vignette: 0.02
        )
    )

    static let ektachromeE100 = FilmStock(
        id: "ektachrome-e100-response",
        displayName: "Ektachrome E100",
        reference: "Neutral ISO 100 E-6 slide response",
        family: .slide,
        tagline: "Clean neutral transparency",
        description: "Extremely fine grain, neutral color balance, bright whites, moderate saturation, and slide-like precision.",
        accent: ProfileAccent(red: 0.34, green: 0.58, blue: 0.92),
        recipe: filmRecipe(
            color: color(exposure: -0.03, contrast: 1.08, saturation: 1.12, temperature: -0.02, tint: 0, red: 1, green: 1.02, blue: 1.04, highlight: (0.04, 0.05, 0.08), shadow: (-0.02, 0.02, 0.06), cmy: (-0.04, 0, -0.06)),
            tone: curve(0.0, 0.18, 0.5, 0.82, 0.99),
            grain: GrainRecipe(amount: 0.14, scale: 0.68, monochrome: true, shadows: 0.28, highlights: 0.18),
            bloom: 0.01,
            halation: 0.02,
            vignette: 0
        )
    )

    static let velvia50 = FilmStock(
        id: "velvia-50-response",
        displayName: "Velvia 50",
        reference: "High-saturation ISO 50 slide response",
        family: .slide,
        tagline: "Landscape chrome punch",
        description: "Very high saturation and contrast, dense greens/blues, fine grain, and narrow slide-film tolerance.",
        accent: ProfileAccent(red: 0.22, green: 0.78, blue: 0.4),
        recipe: filmRecipe(
            color: color(exposure: -0.06, contrast: 1.22, saturation: 1.42, temperature: -0.02, tint: 0.04, red: 1.04, green: 1.1, blue: 1.08, highlight: (0.02, 0.07, 0.08), shadow: (-0.05, 0.08, 0.12), cmy: (-0.15, -0.1, -0.12)),
            tone: curve(0, 0.13, 0.5, 0.88, 1),
            grain: GrainRecipe(amount: 0.12, scale: 0.62, monochrome: true, shadows: 0.25, highlights: 0.12),
            bloom: 0.01,
            halation: 0.02,
            vignette: 0.04
        )
    )

    static let provia100F = FilmStock(
        id: "provia-100f-response",
        displayName: "Provia 100F",
        reference: "Faithful ISO 100 slide response",
        family: .slide,
        tagline: "Faithful crisp chrome",
        description: "Fine-grain slide response with faithful color, strong clarity, rich gradation, and restrained saturation.",
        accent: ProfileAccent(red: 0.28, green: 0.68, blue: 0.86),
        recipe: filmRecipe(
            color: color(exposure: -0.02, contrast: 1.12, saturation: 1.16, temperature: -0.03, tint: 0.02, red: 0.99, green: 1.03, blue: 1.05, highlight: (0.04, 0.04, 0.06), shadow: (-0.02, 0.03, 0.07), cmy: (-0.07, -0.03, -0.05)),
            tone: curve(0, 0.16, 0.5, 0.84, 0.99),
            grain: GrainRecipe(amount: 0.13, scale: 0.62, monochrome: true, shadows: 0.25, highlights: 0.13),
            bloom: 0.01,
            halation: 0.02,
            vignette: 0
        )
    )

    static let triX400 = FilmStock(
        id: "tri-x-400-response",
        displayName: "Tri-X 400",
        reference: "Classic ISO 400 panchromatic black-and-white response",
        family: .blackAndWhite,
        tagline: "Documentary grain",
        description: "Punchy monochrome, classic visible grain, broad latitude, deep midtone contrast, and brilliant highlights.",
        accent: ProfileAccent(red: 0.72, green: 0.68, blue: 0.58),
        recipe: filmRecipe(
            color: color(exposure: 0.02, contrast: 1.24, saturation: 0, temperature: 0.05, red: 1, green: 1, blue: 1, highlight: (0.08, 0.07, 0.05), shadow: (-0.02, -0.02, -0.02)),
            tone: curve(0.04, 0.16, 0.48, 0.84, 0.98),
            grain: GrainRecipe(amount: 0.68, scale: 1.25, monochrome: true, shadows: 0.85, highlights: 0.55),
            bloom: 0.02,
            halation: 0.01,
            vignette: 0.02,
            monochrome: true
        )
    )

    static let hp5Plus = FilmStock(
        id: "hp5-plus-response",
        displayName: "HP5 Plus",
        reference: "Medium-contrast ISO 400 black-and-white response",
        family: .blackAndWhite,
        tagline: "Forgiving mono latitude",
        description: "Medium-contrast monochrome, flexible latitude, cleaner rolloff, and gentler grain than a gritty pushed stock.",
        accent: ProfileAccent(red: 0.62, green: 0.64, blue: 0.62),
        recipe: filmRecipe(
            color: color(exposure: 0.03, contrast: 1.08, saturation: 0, temperature: 0.01, red: 1, green: 1, blue: 1, highlight: (0.05, 0.05, 0.04), shadow: (0.01, 0.01, 0.01)),
            tone: curve(0.05, 0.22, 0.5, 0.8, 0.96),
            grain: GrainRecipe(amount: 0.52, scale: 1.1, monochrome: true, shadows: 0.72, highlights: 0.45),
            bloom: 0.02,
            halation: 0,
            vignette: 0.01,
            monochrome: true
        )
    )

    static let delta3200 = FilmStock(
        id: "delta-3200-response",
        displayName: "Delta 3200",
        reference: "High-speed low-light black-and-white response",
        family: .blackAndWhite,
        tagline: "Low-light heavy grain",
        description: "Fast monochrome response for dark scenes: wide tonal range, big grain, lower crispness, and glowing highlights.",
        accent: ProfileAccent(red: 0.5, green: 0.5, blue: 0.52),
        recipe: filmRecipe(
            color: color(exposure: 0.14, brightness: 0.01, contrast: 1.02, saturation: 0, temperature: 0.02, red: 1, green: 1, blue: 1, highlight: (0.08, 0.08, 0.07), shadow: (0.02, 0.02, 0.02)),
            tone: curve(0.08, 0.26, 0.52, 0.8, 0.96),
            grain: GrainRecipe(amount: 0.95, scale: 1.75, monochrome: true, shadows: 0.95, highlights: 0.72),
            bloom: 0.05,
            halation: 0.02,
            vignette: 0.05,
            monochrome: true
        )
    )

    static let instantColor = FilmStock(
        id: "instant-color-response",
        displayName: "Color Instant",
        reference: "Modern instant color chemistry response",
        family: .instant,
        tagline: "Dreamy instant color",
        description: "Warm, dreamy instant color with creamy highlights, lifted black floor, visible chemistry texture, and white frame.",
        accent: ProfileAccent(red: 0.96, green: 0.84, blue: 0.62),
        recipe: filmRecipe(
            color: color(exposure: 0.06, brightness: 0.03, contrast: 0.9, saturation: 0.94, temperature: 0.24, tint: 0.04, red: 1.05, green: 1.01, blue: 0.92, highlight: (0.3, 0.2, 0.06), shadow: (0.05, 0.02, -0.02), cmy: (-0.04, -0.02, 0.18)),
            tone: curve(0.12, 0.31, 0.54, 0.77, 0.92),
            grain: GrainRecipe(amount: 0.36, scale: 1.35, monochrome: true, shadows: 0.7, highlights: 0.28),
            bloom: 0.12,
            halation: 0.16,
            vignette: 0.02,
            border: .instant
        )
    )

    static let digitalCCD = FilmStock(
        id: "ccd-sensor-response",
        displayName: "CCD Sensor",
        reference: "Early digital CCD/JPEG response",
        family: .digitalSensor,
        tagline: "Digital color pipeline",
        description: "No film stock: clipped sensor highlights, chroma noise, JPEG-era contrast, and cyan/magenta fringing.",
        accent: ProfileAccent(red: 0.42, green: 0.62, blue: 1),
        recipe: filmRecipe(
            color: color(exposure: 0, contrast: 1.04, saturation: 1.02, temperature: -0.04, tint: -0.04, red: 1, green: 1.02, blue: 1.04, highlight: (0.0, 0.04, 0.08), shadow: (-0.05, 0.03, 0.08), cmy: (-0.04, 0.02, -0.08)),
            tone: curve(0, 0.16, 0.5, 0.88, 0.98),
            grain: GrainRecipe(amount: 0.28, scale: 0.8, monochrome: false, shadows: 0.82, highlights: 0.82),
            bloom: 0,
            halation: 0,
            vignette: 0
        )
    )

    // MARK: Helpers

    private static func authoredFilm(
        camera: CameraProfile,
        stock: FilmStock,
        suffix: String,
        name: String,
        tagline: String,
        edit: (inout FilmRecipe) -> Void
    ) -> FilmStock {
        var recipe = RecipeComposer.combine(camera.recipe, stock.recipe)
        recipe.output.aspect = defaultAspect(for: camera)
        recipe.output.labControlsEnabled = false
        edit(&recipe)
        return FilmStock(
            id: "\(camera.id)-\(suffix)",
            displayName: name,
            reference: "\(camera.displayName) authored mode based on \(stock.reference)",
            family: stock.family,
            tagline: tagline,
            description: "\(tagline). Tuned specifically for \(camera.displayName), including its lens, format, colour response, and processing character.",
            accent: ProfileAccent(
                red: (camera.accent.red * 0.5) + (stock.accent.red * 0.5),
                green: (camera.accent.green * 0.5) + (stock.accent.green * 0.5),
                blue: (camera.accent.blue * 0.5) + (stock.accent.blue * 0.5)
            ),
            recipe: recipe,
            behavior: .completeProfile
        )
    }

    private static func defaultAspect(for camera: CameraProfile) -> OutputRecipe.Aspect {
        switch camera.format {
        case .thirtyFive, .disposable, .toy:
            .threeByTwo
        case .medium120, .instant:
            .square
        case .halfFrame:
            .halfFrame
        case .ccd:
            .original
        }
    }

    private static func cameraRecipe(
        color: ColorRecipe,
        tone: ToneCurveRecipe,
        grain: GrainRecipe = GrainRecipe(amount: 0, scale: 0, monochrome: true, shadows: 0, highlights: 0),
        bloom: Double,
        halation: Double,
        vignette: Double,
        lens: LensRecipe,
        aberration: Double,
        dust: Double = 0,
        border: BorderRecipe.Style
    ) -> FilmRecipe {
        FilmRecipe(
            color: color,
            luts: [LUTRecipe(id: "camera-\(border.rawValue)", source: .generatedProfile, dimension: 16, strength: 0.24)],
            tone: tone,
            grain: grain,
            bloom: BloomRecipe(amount: bloom, radius: 8 + bloom * 30),
            halation: HalationRecipe(amount: halation, radius: 7 + halation * 32, warmth: 0.9),
            vignette: VignetteRecipe(amount: vignette, radius: max(0.55, 1.3 - vignette * 0.42), softness: 0.62),
            lens: lens,
            aberration: AberrationRecipe(amount: aberration),
            dust: DustRecipe(amount: dust, scratches: dust * 0.35),
            border: BorderRecipe(style: border, amount: border == .none ? 0 : 0.78)
        )
    }

    private static func filmRecipe(
        color: ColorRecipe,
        tone: ToneCurveRecipe,
        grain: GrainRecipe,
        bloom: Double,
        halation: Double,
        vignette: Double,
        border: BorderRecipe.Style = .none,
        monochrome: Bool = false
    ) -> FilmRecipe {
        var color = color
        color.monochrome = monochrome
        return FilmRecipe(
            color: color,
            luts: [LUTRecipe(id: "film-\(border.rawValue)-\(monochrome ? "mono" : "color")", source: .generatedProfile, dimension: 16, strength: monochrome ? 0.48 : 0.62)],
            tone: tone,
            grain: grain,
            bloom: BloomRecipe(amount: bloom, radius: 7 + bloom * 34),
            halation: HalationRecipe(amount: halation, radius: 8 + halation * 35, warmth: color.temperature >= 0 ? 1 : 0.45),
            vignette: VignetteRecipe(amount: vignette, radius: 1.18, softness: 0.7),
            lens: LensRecipe(softness: 0, edgeSoftness: 0, sharpen: 0, downsample: 1),
            aberration: AberrationRecipe(amount: 0),
            dust: DustRecipe(amount: 0, scratches: 0),
            border: BorderRecipe(style: border, amount: border == .none ? 0 : 1)
        )
    }

    private static func color(
        exposure: Double,
        brightness: Double = 0,
        contrast: Double,
        saturation: Double,
        temperature: Double,
        tint: Double = 0,
        red: Double,
        green: Double,
        blue: Double,
        highlight: (Double, Double, Double) = (0, 0, 0),
        shadow: (Double, Double, Double) = (0, 0, 0),
        cmy: (Double, Double, Double) = (0, 0, 0)
    ) -> ColorRecipe {
        ColorRecipe(
            exposure: exposure,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            temperature: temperature,
            tint: tint,
            redBias: red,
            greenBias: green,
            blueBias: blue,
            shadowRed: shadow.0,
            shadowGreen: shadow.1,
            shadowBlue: shadow.2,
            highlightRed: highlight.0,
            highlightGreen: highlight.1,
            highlightBlue: highlight.2,
            cyanShift: cmy.0,
            magentaShift: cmy.1,
            yellowShift: cmy.2
        )
    }

    private static func curve(_ y0: Double, _ y1: Double, _ y2: Double, _ y3: Double, _ y4: Double) -> ToneCurveRecipe {
        ToneCurveRecipe(
            p0: CGPoint(x: 0, y: y0),
            p1: CGPoint(x: 0.25, y: y1),
            p2: CGPoint(x: 0.5, y: y2),
            p3: CGPoint(x: 0.75, y: y3),
            p4: CGPoint(x: 1, y: y4)
        )
    }
}

enum RecipeComposer {
    static func combine(_ camera: FilmRecipe, _ film: FilmRecipe) -> FilmRecipe {
        FilmRecipe(
            color: ColorRecipe(
                exposure: camera.color.exposure + film.color.exposure,
                brightness: camera.color.brightness + film.color.brightness,
                contrast: camera.color.contrast * film.color.contrast,
                saturation: camera.color.saturation * film.color.saturation,
                temperature: camera.color.temperature + film.color.temperature,
                tint: camera.color.tint + film.color.tint,
                redBias: camera.color.redBias * film.color.redBias,
                greenBias: camera.color.greenBias * film.color.greenBias,
                blueBias: camera.color.blueBias * film.color.blueBias,
                shadowRed: camera.color.shadowRed + film.color.shadowRed,
                shadowGreen: camera.color.shadowGreen + film.color.shadowGreen,
                shadowBlue: camera.color.shadowBlue + film.color.shadowBlue,
                highlightRed: camera.color.highlightRed + film.color.highlightRed,
                highlightGreen: camera.color.highlightGreen + film.color.highlightGreen,
                highlightBlue: camera.color.highlightBlue + film.color.highlightBlue,
                cyanShift: camera.color.cyanShift + film.color.cyanShift,
                magentaShift: camera.color.magentaShift + film.color.magentaShift,
                yellowShift: camera.color.yellowShift + film.color.yellowShift,
                monochrome: camera.color.monochrome || film.color.monochrome
            ),
            luts: [
                LUTRecipe(
                    id: "generated-\(camera.color.hashValue)-\(film.color.hashValue)",
                    source: .generatedProfile,
                    dimension: 16,
                    strength: clamped(0.34 + abs(film.color.temperature) * 0.2 + abs(film.color.cyanShift + film.color.magentaShift + film.color.yellowShift) * 0.08, 0.28, 0.72)
                )
            ],
            tone: ToneCurveRecipe(
                p0: CGPoint(x: 0, y: clamped(camera.tone.p0.y + film.tone.p0.y, 0, 1)),
                p1: CGPoint(x: 0.25, y: clamped((camera.tone.p1.y + film.tone.p1.y) / 2, 0, 1)),
                p2: CGPoint(x: 0.5, y: clamped((camera.tone.p2.y + film.tone.p2.y) / 2, 0, 1)),
                p3: CGPoint(x: 0.75, y: clamped((camera.tone.p3.y + film.tone.p3.y) / 2, 0, 1)),
                p4: CGPoint(x: 1, y: clamped((camera.tone.p4.y + film.tone.p4.y) / 2, 0, 1))
            ),
            grain: GrainRecipe(
                amount: max(0, camera.grain.amount + film.grain.amount),
                scale: max(0.45, 1 + camera.grain.scale + film.grain.scale - 1),
                monochrome: camera.grain.monochrome && film.grain.monochrome,
                shadows: max(camera.grain.shadows, film.grain.shadows),
                highlights: max(camera.grain.highlights, film.grain.highlights)
            ),
            bloom: BloomRecipe(
                amount: camera.bloom.amount + film.bloom.amount,
                radius: max(camera.bloom.radius, film.bloom.radius)
            ),
            halation: HalationRecipe(
                amount: camera.halation.amount + film.halation.amount,
                radius: max(camera.halation.radius, film.halation.radius),
                warmth: (camera.halation.warmth + film.halation.warmth) / 2
            ),
            vignette: VignetteRecipe(
                amount: camera.vignette.amount + film.vignette.amount,
                radius: min(camera.vignette.radius, film.vignette.radius),
                softness: (camera.vignette.softness + film.vignette.softness) / 2
            ),
            lens: camera.lens,
            output: OutputRecipe(
                aspect: camera.output.aspect == .original ? film.output.aspect : camera.output.aspect,
                palette: film.output.palette == .natural ? camera.output.palette : film.output.palette,
                posterizeLevels: max(camera.output.posterizeLevels, film.output.posterizeLevels),
                dateStamp: camera.output.dateStamp || film.output.dateStamp,
                flashFalloff: camera.output.flashFalloff + film.output.flashFalloff,
                labControlsEnabled: camera.output.labControlsEnabled || film.output.labControlsEnabled,
                jpegCrunch: camera.output.jpegCrunch + film.output.jpegCrunch,
                chromaBleed: camera.output.chromaBleed + film.output.chromaBleed,
                lightLeak: camera.output.lightLeak + film.output.lightLeak,
                scanlines: camera.output.scanlines + film.output.scanlines
            ),
            aberration: camera.aberration,
            dust: DustRecipe(
                amount: camera.dust.amount + film.dust.amount,
                scratches: camera.dust.scratches + film.dust.scratches
            ),
            border: camera.border.style == .none ? film.border : camera.border
        )
    }
}
