import SwiftUI

/// Native vector reconstruction of the approved island board. Core owns growth and festival counts.
struct IslandScene: View {
    @Environment(\.colorScheme) private var scheme
    let growth: Int
    let festivals: Int
    let dusk: Bool
    var body: some View {
        let drawingScheme = scheme
        return Canvas { context, size in
            let w = size.width, h = size.height
            func color(_ light: UInt, _ dark: UInt) -> Color { V4.color(light, dark, drawingScheme) }
            func ellipse(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ fill: Color) {
                context.fill(Path(ellipseIn: CGRect(x: x*w, y: y*h, width: width*w, height: height*h)), with: .color(fill))
            }
            func rectangle(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ fill: Color, radius: CGFloat = 4) {
                context.fill(Path(roundedRect: CGRect(x: x*w, y: y*h, width: width*w, height: height*h), cornerRadius: radius), with: .color(fill))
            }
            func polygon(_ points: [(CGFloat, CGFloat)], _ fill: Color, outline: Bool = false) {
                var path = Path(); path.move(to: CGPoint(x: points[0].0*w, y: points[0].1*h))
                for point in points.dropFirst() { path.addLine(to: CGPoint(x: point.0*w, y: point.1*h)) }; path.closeSubpath()
                if outline { context.stroke(path, with: .color(color(0xFFFDF1, 0xE9DFCA)), style: StrokeStyle(lineWidth: 6, lineJoin: .round)) }
                context.fill(path, with: .color(fill))
            }
            let cream = color(0xFFF8DE, 0xD5C9A6), sand = color(0xE9D9A6, 0x8D815E)
            ellipse(0.79, 0.08, 0.13, 0.20, color(0xF3D58A, 0xEAE2CB))
            // Shore and small earned areas use the same soft oval construction as the board.
            ellipse(0.02, 0.44, 0.96, 0.51, cream)
            ellipse(0.03, 0.46, 0.94, 0.47, sand)
            ellipse(0.06, 0.48, 0.87, 0.42, color(0xA8C9B0, 0x3D655A))
            for area in 0..<min(4, festivals) {
                let x = 0.69 + CGFloat(area % 2)*0.10, y = 0.84 + CGFloat(area / 2)*0.06
                ellipse(x, y, 0.16, 0.09, cream); ellipse(x+0.01, y+0.01, 0.14, 0.065, color(0xA8C9B0, 0x3D655A))
            }
            // House: cream walls, coral roof, windows, and the board's small green shadow.
            polygon([(0.14,0.65),(0.25,0.65),(0.27,0.73),(0.13,0.73)], color(0x719D82,0x315547))
            rectangle(0.135, 0.48, 0.12, 0.23, cream, radius: 5)
            polygon([(0.12,0.49),(0.195,0.34),(0.27,0.49)], color(0xC8735E,0xAA7568), outline: true)
            rectangle(0.155,0.53,0.019,0.045,color(0xF3D58A,0xB6A060),radius: 2)
            rectangle(0.215,0.53,0.019,0.045,color(0xF3D58A,0xB6A060),radius: 2)
            // Lighthouse and its lantern, positioned behind the festival string.
            rectangle(0.32,0.36,0.023,0.27,cream,radius: 3)
            rectangle(0.326,0.40,0.009,0.20,color(0x8B7556,0x746B57),radius: 1)
            rectangle(0.306,0.28,0.053,0.14,cream,radius: 6)
            rectangle(0.318,0.31,0.03,0.08,color(0xF3D58A,0xC5AB68),radius: 3)
            polygon([(0.315,0.305),(0.334,0.268),(0.353,0.305)],color(0xD58B60,0xA47F62))
            var string = Path(); string.move(to: CGPoint(x: w*0.24,y:h*0.42))
            string.addQuadCurve(to: CGPoint(x:w*0.90,y:h*0.42),control:CGPoint(x:w*0.57,y:h*0.58))
            context.stroke(string,with:.color(color(0x695D3E,0xBFB393)),lineWidth:1.5)
            for lamp in 0..<7 {
                let t = CGFloat(lamp)/6, x = 0.25+t*0.64, y = 0.40+0.10*sin(t * .pi)
                ellipse(x-0.014,y-0.017,0.028,0.047,color(0xF3D58A,0xCAB36C).opacity(festivals > 0 ? 1 : 0.45))
            }
            let positions: [(CGFloat,CGFloat)] = [(0.41,0.65),(0.61,0.72),(0.78,0.67),(0.18,0.81),(0.52,0.80),(0.87,0.79),(0.71,0.59)]
            for index in 0..<min(7,growth) {
                let (x,y) = positions[index]
                if index == 0 {
                    // Rounded bird motif from the handoff, with a warm cheek.
                    ellipse(x-0.032,y-0.035,0.076,0.105,cream); ellipse(x+0.017,y-0.07,0.035,0.067,cream)
                    ellipse(x-0.02,y-0.015,0.017,0.025,color(0xEDB8A8,0xBF9589))
                } else if index % 2 == 1 {
                    polygon([(x,y-0.055),(x-0.018,y+0.026),(x+0.018,y+0.026)],color(0x719D82,0x6A9983))
                } else {
                    ellipse(x-0.025,y-0.013,0.05,0.045,cream)
                    ellipse(x-0.02,y-0.01,0.025,0.032,color(0x719D82,0x6A9983))
                    ellipse(x+0.004,y-0.005,0.014,0.023,color(0xF3D58A,0xCAB36C))
                }
            }
            for wave in 0..<4 {
                let x = CGFloat(wave)*0.30-0.05, y = wave % 2 == 0 ? 0.44 : 0.88
                var path = Path(); path.move(to:CGPoint(x:x*w,y:y*h))
                path.addCurve(to:CGPoint(x:(x+0.09)*w,y:y*h),control1:CGPoint(x:(x+0.035)*w,y:(y+0.035)*h),control2:CGPoint(x:(x+0.055)*w,y:(y-0.035)*h))
                context.stroke(path,with:.color(color(0x8DA3D2,0x667BA8)),style:StrokeStyle(lineWidth:2,lineCap:.round))
            }
        }
        .background(LinearGradient(colors:[V4.color(dusk ? 0xE4CEDB : 0xCEE2EC,0x253249,scheme),V4.color(0xBFCBE9,0x343B56,scheme)],startPoint:.top,endPoint:.bottom))
        .clipShape(RoundedRectangle(cornerRadius:28))
    }
}
